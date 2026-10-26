from datetime import datetime, timedelta

import pytest
from httpx import AsyncClient

from tests.factories import PROJECTS_URL, create_project, create_task, project_names, tasks_url

Headers = dict[str, str]


class TestCreateProject:
    async def test_creates_project_with_defaults(self, client: AsyncClient, user_a: Headers) -> None:
        response = await client.post(PROJECTS_URL, json={"name": "  Learn Flutter  "}, headers=user_a)

        assert response.status_code == 201
        body = response.json()
        assert body["name"] == "Learn Flutter"  # obciete spacje
        assert body["description"] is None
        assert body["color"] == "#673AB7"
        assert body["task_count"] == 0
        assert body["completed_task_count"] == 0
        assert datetime.fromisoformat(body["created_at"]).utcoffset() == timedelta(0)  # zawsze UTC

    async def test_new_projects_are_appended_to_the_end(self, client: AsyncClient, user_a: Headers) -> None:
        for name in ("A", "B", "C"):
            await create_project(client, user_a, name=name)

        assert await project_names(client, user_a) == ["A", "B", "C"]

    async def test_color_is_normalised_to_upper_case(self, client: AsyncClient, user_a: Headers) -> None:
        project = await create_project(client, user_a, color="#ff5722")

        assert project["color"] == "#FF5722"

    @pytest.mark.parametrize(
        "payload",
        [
            pytest.param({}, id="missing-name"),
            pytest.param({"name": "   "}, id="blank-name"),
            pytest.param({"name": "x" * 101}, id="name-too-long"),
            pytest.param({"name": "P", "color": "red"}, id="invalid-color"),
            pytest.param({"name": "P", "unknown": 1}, id="unknown-field"),
        ],
    )
    async def test_rejects_invalid_payload(self, client: AsyncClient, user_a: Headers, payload: dict) -> None:
        response = await client.post(PROJECTS_URL, json=payload, headers=user_a)

        assert response.status_code == 422

    async def test_enforces_project_limit(
        self, client: AsyncClient, user_a: Headers, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        from src.core.config import settings

        monkeypatch.setattr(settings, "MAX_PROJECTS_PER_USER", 2)
        await create_project(client, user_a)
        await create_project(client, user_a)

        response = await client.post(PROJECTS_URL, json={"name": "Third"}, headers=user_a)

        assert response.status_code == 409
        assert response.json()["error_code"] == "LIMIT_EXCEEDED"


class TestReadProjects:
    async def test_list_contains_task_statistics(self, client: AsyncClient, user_a: Headers) -> None:
        project = await create_project(client, user_a)
        task = await create_task(client, user_a, project["id"])
        await create_task(client, user_a, project["id"])
        await client.patch(f"{tasks_url(project['id'])}/{task['id']}", json={"is_completed": True}, headers=user_a)

        listed = (await client.get(PROJECTS_URL, headers=user_a)).json()
        single = (await client.get(f"{PROJECTS_URL}/{project['id']}", headers=user_a)).json()

        assert listed[0]["task_count"] == single["task_count"] == 2
        assert listed[0]["completed_task_count"] == single["completed_task_count"] == 1

    async def test_get_unknown_project_returns_404(self, client: AsyncClient, user_a: Headers) -> None:
        response = await client.get(f"{PROJECTS_URL}/999", headers=user_a)

        assert response.status_code == 404
        assert response.json()["error_code"] == "PROJECT_NOT_FOUND"


class TestUpdateProject:
    async def test_partial_update_changes_only_sent_fields(self, client: AsyncClient, user_a: Headers) -> None:
        project = await create_project(client, user_a, name="Old", description="Desc", color="#2196F3")

        response = await client.patch(f"{PROJECTS_URL}/{project['id']}", json={"name": "New"}, headers=user_a)

        assert response.status_code == 200
        body = response.json()
        assert body["name"] == "New"
        assert body["description"] == "Desc"
        assert body["color"] == "#2196F3"
        assert body["updated_at"] >= project["updated_at"]

    async def test_description_can_be_cleared(self, client: AsyncClient, user_a: Headers) -> None:
        project = await create_project(client, user_a, description="Desc")

        response = await client.patch(f"{PROJECTS_URL}/{project['id']}", json={"description": None}, headers=user_a)

        assert response.json()["description"] is None

    async def test_name_cannot_be_null(self, client: AsyncClient, user_a: Headers) -> None:
        project = await create_project(client, user_a)

        response = await client.patch(f"{PROJECTS_URL}/{project['id']}", json={"name": None}, headers=user_a)

        assert response.status_code == 422


class TestDeleteProject:
    async def test_delete_removes_project_and_its_tasks(self, client: AsyncClient, user_a: Headers) -> None:
        project = await create_project(client, user_a)
        await create_task(client, user_a, project["id"])

        response = await client.delete(f"{PROJECTS_URL}/{project['id']}", headers=user_a)

        assert response.status_code == 204
        assert (await client.get(f"{PROJECTS_URL}/{project['id']}", headers=user_a)).status_code == 404
        assert (await client.get(tasks_url(project["id"]), headers=user_a)).status_code == 404

    async def test_cascade_removes_tasks_in_database(self, client: AsyncClient, user_a: Headers, engine) -> None:
        from sqlalchemy import func, select

        from src.db.models import Task

        project = await create_project(client, user_a)
        await create_task(client, user_a, project["id"])
        await client.delete(f"{PROJECTS_URL}/{project['id']}", headers=user_a)

        async with engine.connect() as conn:
            remaining = (await conn.execute(select(func.count()).select_from(Task))).scalar_one()
        assert remaining == 0


class TestReorderProjects:
    @pytest.fixture
    async def projects(self, client: AsyncClient, user_a: Headers) -> dict[str, int]:
        return {name: (await create_project(client, user_a, name=name))["id"] for name in "ABCD"}

    async def _reorder(self, client: AsyncClient, headers: Headers, project_id: int, **body) -> int:
        response = await client.post(f"{PROJECTS_URL}/{project_id}/reorder", json=body, headers=headers)
        return response.status_code

    async def test_move_to_top(self, client: AsyncClient, user_a: Headers, projects: dict[str, int]) -> None:
        status = await self._reorder(client, user_a, projects["C"], prev_id=None, next_id=projects["A"])

        assert status == 200
        assert await project_names(client, user_a) == ["C", "A", "B", "D"]

    async def test_move_to_bottom(self, client: AsyncClient, user_a: Headers, projects: dict[str, int]) -> None:
        await self._reorder(client, user_a, projects["A"], prev_id=projects["D"], next_id=None)

        assert await project_names(client, user_a) == ["B", "C", "D", "A"]

    async def test_move_between(self, client: AsyncClient, user_a: Headers, projects: dict[str, int]) -> None:
        await self._reorder(client, user_a, projects["D"], prev_id=projects["A"], next_id=projects["B"])

        assert await project_names(client, user_a) == ["A", "D", "B", "C"]

    async def test_stale_next_id_is_corrected_by_server(
        self, client: AsyncClient, user_a: Headers, projects: dict[str, int]
    ) -> None:
        # Klient mysli, ze pod A jest C (nieaktualna lista) - serwer i tak wstawia tuz pod A
        await self._reorder(client, user_a, projects["D"], prev_id=projects["A"], next_id=projects["C"])

        assert await project_names(client, user_a) == ["A", "D", "B", "C"]

    async def test_many_moves_into_the_same_gap_trigger_renumbering(
        self, client: AsyncClient, user_a: Headers, projects: dict[str, int]
    ) -> None:
        # Kazde przesuniecie polowi przerwe miedzy A i kolejnym elementem.
        # Po ~40 iteracjach float konczy precyzje - serwis musi przenumerowac liste.
        moving = [projects["B"], projects["C"]]
        for i in range(80):
            await self._reorder(client, user_a, moving[i % 2], prev_id=projects["A"])

        names = await project_names(client, user_a)
        assert names[0] == "A" and names[-1] == "D"
        positions = [p["position"] for p in (await client.get(PROJECTS_URL, headers=user_a)).json()]
        assert positions == sorted(positions) and len(set(positions)) == len(positions)

    async def test_rejects_self_as_neighbour(
        self, client: AsyncClient, user_a: Headers, projects: dict[str, int]
    ) -> None:
        status = await self._reorder(client, user_a, projects["A"], prev_id=projects["A"])

        assert status == 400

    async def test_rejects_unknown_neighbour(
        self, client: AsyncClient, user_a: Headers, projects: dict[str, int]
    ) -> None:
        status = await self._reorder(client, user_a, projects["A"], prev_id=999)

        assert status == 400


class TestIsolationBetweenUsers:
    async def test_users_see_only_their_projects(self, client: AsyncClient, user_a: Headers, user_b: Headers) -> None:
        await create_project(client, user_a, name="Mine")
        await create_project(client, user_b, name="Theirs")

        assert await project_names(client, user_a) == ["Mine"]
        assert await project_names(client, user_b) == ["Theirs"]

    @pytest.mark.parametrize(
        ("method", "suffix", "body"),
        [
            ("GET", "", None),
            ("PATCH", "", {"name": "Hacked"}),
            ("DELETE", "", None),
            ("POST", "/reorder", {"prev_id": None, "next_id": None}),
        ],
    )
    async def test_foreign_project_is_not_accessible(
        self, client: AsyncClient, user_a: Headers, user_b: Headers, method: str, suffix: str, body: dict | None
    ) -> None:
        project = await create_project(client, user_a)

        response = await client.request(method, f"{PROJECTS_URL}/{project['id']}{suffix}", json=body, headers=user_b)

        assert response.status_code == 404

    async def test_foreign_project_cannot_be_used_as_neighbour(
        self, client: AsyncClient, user_a: Headers, user_b: Headers
    ) -> None:
        mine = await create_project(client, user_a)
        theirs = await create_project(client, user_b)

        response = await client.post(
            f"{PROJECTS_URL}/{mine['id']}/reorder", json={"prev_id": theirs["id"]}, headers=user_a
        )

        assert response.status_code == 400
