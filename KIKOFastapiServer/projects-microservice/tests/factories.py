from datetime import datetime, timedelta, timezone
from typing import Any

from httpx import AsyncClient
from jose import jwt

from src.core.config import settings

USER_A = "11111111-1111-1111-1111-111111111111"
USER_B = "22222222-2222-2222-2222-222222222222"

PROJECTS_URL = "/api/v1/projects"


def make_token(
    user_id: str,
    token_type: str = "access",
    expires_in: timedelta = timedelta(minutes=15),
    secret: str | None = None,
) -> str:
    """Token w tym samym formacie co wystawia auth-microservice."""
    payload = {"sub": user_id, "type": token_type, "exp": datetime.now(timezone.utc) + expires_in}
    return jwt.encode(payload, secret or settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def auth_header(user_id: str, **kwargs: Any) -> dict[str, str]:
    return {"Authorization": f"Bearer {make_token(user_id, **kwargs)}"}


def tasks_url(project_id: int) -> str:
    return f"{PROJECTS_URL}/{project_id}/tasks"


async def create_project(client: AsyncClient, headers: dict[str, str], **fields: Any) -> dict[str, Any]:
    payload = {"name": "Project", **fields}
    response = await client.post(PROJECTS_URL, json=payload, headers=headers)
    assert response.status_code == 201, response.text
    return response.json()


async def create_task(
    client: AsyncClient, headers: dict[str, str], project_id: int, **fields: Any
) -> dict[str, Any]:
    payload = {"title": "Task", **fields}
    response = await client.post(tasks_url(project_id), json=payload, headers=headers)
    assert response.status_code == 201, response.text
    return response.json()


async def project_names(client: AsyncClient, headers: dict[str, str]) -> list[str]:
    response = await client.get(PROJECTS_URL, headers=headers)
    assert response.status_code == 200, response.text
    return [project["name"] for project in response.json()]


async def task_titles(client: AsyncClient, headers: dict[str, str], project_id: int) -> list[str]:
    response = await client.get(tasks_url(project_id), headers=headers)
    assert response.status_code == 200, response.text
    return [task["title"] for task in response.json()]
