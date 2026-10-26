import pytest
from httpx import AsyncClient

from tests.factories import create_project, create_task, task_titles, tasks_url

Headers = dict[str, str]


@pytest.fixture
async def project(client: AsyncClient, user_a: Headers) -> dict:
    return await create_project(client, user_a, name="Main project")


class TestCreateTask:
    async def test_creates_task_with_all_fields(self, client: AsyncClient, user_a: Headers, project: dict) -> None:
        payload = {"title": " Write tests ", "description": "pytest", "priority": "high", "due_date": "2026-12-24"}

        response = await client.post(tasks_url(project["id"]), json=payload, headers=user_a)

        assert response.status_code == 201
        body = response.json()
        assert body["title"] == "Write tests"
        assert body["description"] == "pytest"
        assert body["priority"] == "high"
        assert body["due_date"] == "2026-12-24"
        assert body["project_id"] == project["id"]
        assert body["is_completed"] is False
        assert body["completed_at"] is None

    async def test_defaults(self, client: AsyncClient, user_a: Headers, project: dict) -> None:
        task = await create_task(client, user_a, project["id"], description="   ")

        assert task["priority"] == "none"
        assert task["due_date"] is None
        assert task["description"] is None  # same spacje -> NULL

    @pytest.mark.parametrize(
        "payload",
        [
            pytest.param({"title": ""}, id="empty-title"),
            pytest.param({"title": "x" * 201}, id="title-too-long"),
            pytest.param({"title": "T", "priority": "urgent"}, id="invalid-priority"),
            pytest.param({"title": "T", "due_date": "not-a-date"}, id="invalid-date"),
        ],
    )
    async def test_rejects_invalid_payload(
        self, client: AsyncClient, user_a: Headers, project: dict, payload: dict
    ) -> None:
        response = await client.post(tasks_url(project["id"]), json=payload, headers=user_a)

        assert response.status_code == 422

    async def test_unknown_project_returns_404(self, client: AsyncClient, user_a: Headers) -> None:
        response = await client.post(tasks_url(999), json={"title": "T"}, headers=user_a)

        assert response.status_code == 404
        assert response.json()["error_code"] == "PROJECT_NOT_FOUND"

    async def test_tasks_are_scoped_to_their_project(self, client: AsyncClient, user_a: Headers, project: dict) -> None:
        other = await create_project(client, user_a, name="Other")
        await create_task(client, user_a, project["id"], title="In main")
        await create_task(client, user_a, other["id"], title="In other")

        assert await task_titles(client, user_a, project["id"]) == ["In main"]
        assert await task_titles(client, user_a, other["id"]) == ["In other"]


class TestUpdateTask:
    async def test_completing_sets_completed_at(self, client: AsyncClient, user_a: Headers, project: dict) -> None:
        task = await create_task(client, user_a, project["id"])
        url = f"{tasks_url(project['id'])}/{task['id']}"

        done = (await client.patch(url, json={"is_completed": True}, headers=user_a)).json()
        undone = (await client.patch(url, json={"is_completed": False}, headers=user_a)).json()

        assert done["is_completed"] is True and done["completed_at"] is not None
        assert undone["is_completed"] is False and undone["completed_at"] is None

    async def test_partial_update_and_clearing_optional_fields(
        self, client: AsyncClient, user_a: Headers, project: dict
    ) -> None:
        task = await create_task(client, user_a, project["id"], description="D", due_date="2026-01-01", priority="low")
        url = f"{tasks_url(project['id'])}/{task['id']}"

        body = (await client.patch(url, json={"due_date": None, "priority": "medium"}, headers=user_a)).json()

        assert body["due_date"] is None
        assert body["priority"] == "medium"
        assert body["description"] == "D"
        assert body["title"] == task["title"]

    async def test_title_cannot_be_null(self, client: AsyncClient, user_a: Headers, project: dict) -> None:
        task = await create_task(client, user_a, project["id"])

        response = await client.patch(f"{tasks_url(project['id'])}/{task['id']}", json={"title": None}, headers=user_a)

        assert response.status_code == 422

    async def test_task_from_another_project_is_not_found(
        self, client: AsyncClient, user_a: Headers, project: dict
    ) -> None:
        other = await create_project(client, user_a, name="Other")
        task = await create_task(client, user_a, other["id"])

        response = await client.patch(f"{tasks_url(project['id'])}/{task['id']}", json={"title": "X"}, headers=user_a)

        assert response.status_code == 404
        assert response.json()["error_code"] == "TASK_NOT_FOUND"


class TestDeleteTask:
    async def test_delete(self, client: AsyncClient, user_a: Headers, project: dict) -> None:
        task = await create_task(client, user_a, project["id"])
        url = f"{tasks_url(project['id'])}/{task['id']}"

        assert (await client.delete(url, headers=user_a)).status_code == 204
        assert (await client.get(url, headers=user_a)).status_code == 404
        assert await task_titles(client, user_a, project["id"]) == []


class TestReorderTasks:
    @pytest.fixture
    async def tasks(self, client: AsyncClient, user_a: Headers, project: dict) -> dict[str, int]:
        return {title: (await create_task(client, user_a, project["id"], title=title))["id"] for title in "ABC"}

    async def _reorder(self, client: AsyncClient, headers: Headers, project_id: int, task_id: int, **body) -> int:
        response = await client.post(f"{tasks_url(project_id)}/{task_id}/reorder", json=body, headers=headers)
        return response.status_code

    async def test_move_to_top_and_bottom(
        self, client: AsyncClient, user_a: Headers, project: dict, tasks: dict[str, int]
    ) -> None:
        assert await self._reorder(client, user_a, project["id"], tasks["C"], next_id=tasks["A"]) == 200
        assert await task_titles(client, user_a, project["id"]) == ["C", "A", "B"]

        assert await self._reorder(client, user_a, project["id"], tasks["C"], prev_id=tasks["B"]) == 200
        assert await task_titles(client, user_a, project["id"]) == ["A", "B", "C"]

    async def test_move_between(self, client: AsyncClient, user_a: Headers, project: dict, tasks: dict[str, int]) -> None:
        await self._reorder(client, user_a, project["id"], tasks["C"], prev_id=tasks["A"], next_id=tasks["B"])

        assert await task_titles(client, user_a, project["id"]) == ["A", "C", "B"]

    async def test_neighbour_from_another_project_is_rejected(
        self, client: AsyncClient, user_a: Headers, project: dict, tasks: dict[str, int]
    ) -> None:
        other = await create_project(client, user_a, name="Other")
        foreign = await create_task(client, user_a, other["id"])

        status = await self._reorder(client, user_a, project["id"], tasks["A"], prev_id=foreign["id"])

        assert status == 400

    async def test_prev_and_next_must_differ(
        self, client: AsyncClient, user_a: Headers, project: dict, tasks: dict[str, int]
    ) -> None:
        status = await self._reorder(client, user_a, project["id"], tasks["A"], prev_id=tasks["B"], next_id=tasks["B"])

        assert status == 422


class TestTaskIsolationBetweenUsers:
    async def test_foreign_project_tasks_are_not_accessible(
        self, client: AsyncClient, user_a: Headers, user_b: Headers, project: dict
    ) -> None:
        task = await create_task(client, user_a, project["id"])
        url = f"{tasks_url(project['id'])}/{task['id']}"

        assert (await client.get(tasks_url(project["id"]), headers=user_b)).status_code == 404
        assert (await client.post(tasks_url(project["id"]), json={"title": "X"}, headers=user_b)).status_code == 404
        assert (await client.patch(url, json={"title": "X"}, headers=user_b)).status_code == 404
        assert (await client.delete(url, headers=user_b)).status_code == 404
        assert await task_titles(client, user_a, project["id"]) == [task["title"]]
