import pytest
from src.db.models.user import User
from src.core.security import pwd_context
from sqlalchemy.future import select
from tests.conftest import TestingSessionLocal

@pytest.mark.asyncio
async def test_not_found(client):
    response = client.get("/invalid-endpoint")
    assert response.status_code == 404
    assert response.json() == {"detail": "Not Found"}

@pytest.mark.asyncio
async def test_get_root(client):
    response = client.get("/")
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/json"
    assert response.json() == {"status": "ok"}

@pytest.fixture
def valid_register_data():
    return {
        "email": "user2@example.com",
        "username": "john2_doe",
        "password": "secure123"
    }

@pytest.mark.asyncio
async def test_post_register_user(client, valid_register_data):
    response = client.post("/api/v1/auth/register", json=valid_register_data)
    assert response.status_code == 201
    assert response.headers["content-type"] == "application/json"
    response_json = response.json()
    assert "id" in response_json
    assert response_json["username"] == valid_register_data["username"]
    assert response_json["email"] == valid_register_data["email"]


@pytest.mark.asyncio
@pytest.mark.parametrize("invalid_email", [
    "invalid-email",
    "user@",
    "@domain.com",
    "user@domain",
    "user.domain.com",
    "user@.com"
])
async def test_post_register_user_invalid_email(client, valid_register_data, invalid_email):
    invalid_data = valid_register_data.copy()
    invalid_data["email"] = invalid_email
    response = client.post("/api/v1/auth/register", json=invalid_data)
    assert response.status_code == 422

    response_json = response.json()
    assert "detail" in response_json
    assert response_json["detail"][0]["loc"] == ["body", "email"]

    errors = response_json["detail"]
    assert any(
        error["loc"] == ["body", "email"] and error["type"] == "value_error"
        for error in errors
    )
    assert any(
        error["loc"] == ["body", "email"] and "email address" in error["msg"].lower()
        for error in errors
    )


@pytest.mark.asyncio
@pytest.mark.parametrize("invalid_username, expected_error_msg", [
    ("", "Value error, The username cannot be empty or consist only of whitespace."),
    ("   ", "Value error, The username cannot be empty or consist only of whitespace."),
    ("  john", "Value error, The username cannot contain spaces at the beginning or end."),
    ("john  ", "Value error, The username cannot contain spaces at the beginning or end."),
])
async def test_post_register_user_invalid_username(client, valid_register_data, invalid_username, expected_error_msg):
    invalid_data = valid_register_data.copy()
    invalid_data["username"] = invalid_username
    response = client.post("/api/v1/auth/register", json=invalid_data)
    assert response.status_code == 422
    response_json = response.json()
    assert "detail" in response_json
    errors = response_json["detail"]
    assert any(
        error["loc"] == ["body", "username"] and error["msg"] == expected_error_msg
        for error in errors
    ), f"Expected error with loc=['body', 'username'] and msg='{expected_error_msg}', got {errors}"


async def test_post_register_user_saves_to_database(client, valid_register_data):
    response = client.post("/api/v1/auth/register", json=valid_register_data)
    assert response.status_code == 201
    response_json = response.json()
    assert response_json["username"] == valid_register_data["username"]
    assert response_json["email"] == valid_register_data["email"]
    assert "id" in response_json
    assert response_json["account_role"] == "REGULAR"
    assert response_json["account_subscription"] == "FREE"

    async with TestingSessionLocal() as session:
        result = await session.execute(
            select(User).filter(User.email == valid_register_data["email"])
        )
        db_user = result.scalars().first()

        assert db_user is not None
        assert db_user.username == valid_register_data["username"]
        assert db_user.email == valid_register_data["email"]
        assert db_user.account_role == "REGULAR"
        assert db_user.account_subscription == "FREE"
        assert db_user.created_at is not None
        assert pwd_context.verify(valid_register_data["password"], db_user.hashed_password)


@pytest.mark.asyncio
async def test_post_regitster_user_duplicate_username(client, valid_register_data):
    response = client.post("/api/v1/auth/register", json=valid_register_data)
    assert response.status_code == 201
    assert response.json()["username"] == valid_register_data["username"]

    duplicate_data = valid_register_data.copy()
    duplicate_data["email"] = "different@example.com"
    response = client.post("/api/v1/auth/register", json=duplicate_data)

    assert response.status_code == 409
    assert response.json() == {"detail":"Username already taken"}


@pytest.mark.asyncio
async def test_logout_user(client, valid_register_data):
    # 1. Zarejestruj i zaloguj użytkownika, aby uzyskać tokeny
    client.post("/api/v1/auth/register", json=valid_register_data)
    login_payload = {
        "username": valid_register_data["email"],
        "password": valid_register_data["password"]
    }
    login_response = client.post("/api/v1/auth/login", data=login_payload)
    assert login_response.status_code == 200
    tokens = login_response.json()
    access_token = tokens["access_token"]
    refresh_token = tokens["refresh_token"]

    # 2. Sprawdź, czy chroniony endpoint działa
    headers = {"Authorization": f"Bearer {access_token}"}
    protected_response = client.get("/api/v1/data/test-data", headers=headers)
    assert protected_response.status_code == 200

    # 3. Wyloguj użytkownika
    logout_response = client.post("/api/v1/auth/logout", json={"refresh_token": refresh_token})
    assert logout_response.status_code == 204

     # 4. Sprawdź, czy odświeżenie tokena teraz zawiedzie
    refresh_response = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert refresh_response.status_code == 401
    assert "Invalid or expired refresh token" in refresh_response.json()["detail"]
    


