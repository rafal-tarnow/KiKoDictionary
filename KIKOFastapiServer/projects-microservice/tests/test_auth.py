from datetime import timedelta

import pytest
from httpx import AsyncClient

from tests.factories import PROJECTS_URL, USER_A, auth_header


async def test_missing_token_is_rejected(client: AsyncClient) -> None:
    response = await client.get(PROJECTS_URL)

    assert response.status_code == 401
    assert response.json()["error_code"] == "NOT_AUTHENTICATED"
    assert response.headers["www-authenticate"] == "Bearer"


@pytest.mark.parametrize(
    "headers",
    [
        pytest.param({"Authorization": "Bearer not-a-jwt"}, id="garbage"),
        pytest.param(auth_header(USER_A, secret="other-secret"), id="wrong-signature"),
        pytest.param(auth_header(USER_A, expires_in=timedelta(minutes=-1)), id="expired"),
        pytest.param(auth_header(USER_A, token_type="refresh"), id="refresh-token"),
    ],
)
async def test_invalid_tokens_are_rejected(client: AsyncClient, headers: dict[str, str]) -> None:
    response = await client.get(PROJECTS_URL, headers=headers)

    assert response.status_code == 401
    assert response.json()["detail"] == "Could not validate credentials"


async def test_valid_access_token_is_accepted(client: AsyncClient, user_a: dict[str, str]) -> None:
    response = await client.get(PROJECTS_URL, headers=user_a)

    assert response.status_code == 200
    assert response.json() == []
