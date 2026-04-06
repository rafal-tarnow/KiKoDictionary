import pytest
import uuid
from unittest.mock import patch
from src.db.models.user import User
from src.core.security import pwd_context
from sqlalchemy.future import select
from tests.conftest import TestingSessionLocal


# Tworzymy fałszywą odpowiedź dla biblioteki HTTPX
class MockResponse:
    @property
    def status_code(self):
        return 200
        
    def json(self):
        return {"is_valid": True} # Zawsze zwracamy sukces captchy
        
    def raise_for_status(self):
        pass

@pytest.fixture(autouse=True)
def mock_captcha_verification():
    """
    Zastępuje prawdziwe zapytanie HTTP do serwisu Captcha.
    Dzięki temu testy przechodzą w izolacji, nawet gdy serwis Captcha jest wyłączony.
    """
    async def mock_post(*args, **kwargs):
        return MockResponse()
        
    with patch("httpx.AsyncClient.post", side_effect=mock_post):
        yield
    

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
        "password": "secure123",
        "captcha_id": str(uuid.uuid4()), # <--- Dodane pole wymagane przez Pydantic
        "captcha_answer": "123456"       # <--- Dodane pole wymagane przez Pydantic
    }

@pytest.mark.asyncio
async def test_post_register_user(client, valid_register_data):
    response = client.post("/api/v1/auth/register", json=valid_register_data)
    assert response.status_code == 201
    
    response_json = response.json()
    assert "id" in response_json
    assert response_json["email"] == valid_register_data["email"]
    
    # ================= [ZMIANA 2]: Upewniamy się, że API wygenerowało username! =================
    assert "username" in response_json
    assert len(response_json["username"]) > 5 # Upewniamy się, że Coolname zadziałał
    # ============================================================================================


@pytest.mark.asyncio
@pytest.mark.parametrize("invalid_email", [
    "invalid-email", "user@", "@domain.com", "user@domain", "user.domain.com", "user@.com"
])
async def test_post_register_user_invalid_email(client, valid_register_data, invalid_email):
    invalid_data = valid_register_data.copy()
    invalid_data["email"] = invalid_email
    response = client.post("/api/v1/auth/register", json=invalid_data)
    assert response.status_code == 422


# ================= [ZMIANA 1]: Naprawa błędu KeyError =================
async def test_post_register_user_saves_to_database(client, valid_register_data):
    response = client.post("/api/v1/auth/register", json=valid_register_data)
    assert response.status_code == 201
    response_json = response.json()
    
    # USUNIĘTO: assert response_json["username"] == valid_register_data["username"]
    assert "username" in response_json # Upewniamy się tylko, że API go zwróciło
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
        # Sprawdzamy czy generator w repozytorium zadziałał poprawnie
        assert db_user.username is not None 
        assert len(db_user.username) > 0
        
        assert db_user.email == valid_register_data["email"]
        assert db_user.account_role == "REGULAR"
        assert db_user.account_subscription == "FREE"
        assert db_user.created_at is not None
        assert pwd_context.verify(valid_register_data["password"], db_user.hashed_password)
# ======================================================================


# ================= [ZMIANA 2]: Nowy test zapobiegający duplikatom =================
@pytest.mark.asyncio
async def test_post_register_user_duplicate_email(client, valid_register_data):
    # 1. Rejestrujemy użytkownika pierwszy raz (Sukces)
    response1 = client.post("/api/v1/auth/register", json=valid_register_data)
    assert response1.status_code == 201

    # 2. Próbujemy zarejestrować drugiego usera NA TEN SAM EMAIL (Błąd)
    duplicate_data = valid_register_data.copy()
    duplicate_data["password"] = "InneHaslo123" # Hasło inne, ale email ten sam
    
    response2 = client.post("/api/v1/auth/register", json=duplicate_data)

    assert response2.status_code == 409
    assert response2.json() == {"detail": "Email already registered"}
# ==================================================================================


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
    assert "Token has been compromised" in refresh_response.json()["detail"]
    

@pytest.mark.asyncio
@pytest.mark.parametrize("invalid_password, expected_error_msg", [
    ("a1B2c3d", "Value error, Password must be at least 8 characters long"),  # 7 znaków
    ("1234567", "Value error, Password must be at least 8 characters long"),  # 7 cyfr
    ("abcdefg", "Value error, Password must be at least 8 characters long"),  # 7 liter
])
async def test_post_register_user_invalid_password(client, valid_register_data, invalid_password, expected_error_msg):
    """
    Testuje wymogi bezpieczeństwa (min. 8 znaków).
    """
    invalid_data = valid_register_data.copy()
    invalid_data["password"] = invalid_password
    
    response = client.post("/api/v1/auth/register", json=invalid_data)
    assert response.status_code == 422
    
    response_json = response.json()
    assert "detail" in response_json
    errors = response_json["detail"]
    
    assert any(
        error["loc"] == ["body", "password"] and error["msg"] == expected_error_msg
        for error in errors
    ), f"Expected password error: '{expected_error_msg}', got {errors}"


# ================= [ZMIANA 3]: Nowe testy dla zmiany loginu =================
@pytest.mark.asyncio
async def test_update_username_success_and_conflict(client, valid_register_data):
    # 1. Zarejestruj i zaloguj Usera 1 (Nasza ofiara testowa)
    client.post("/api/v1/auth/register", json=valid_register_data)
    login_res1 = client.post("/api/v1/auth/login", data={"username": valid_register_data["email"], "password": valid_register_data["password"]})
    token1 = login_res1.json()["access_token"]
    headers1 = {"Authorization": f"Bearer {token1}"}

    # 2. Zarejestruj i zaloguj Usera 2 (Blokujący)
    user2_data = valid_register_data.copy()
    user2_data["email"] = "zajety@example.com"
    client.post("/api/v1/auth/register", json=user2_data)
    
    # 3. User 1 zmienia swój login na coś unikalnego (SUKCES)
    new_name = "UniqueTiger99"
    update_res = client.patch("/api/v1/users/me/username", json={"username": new_name}, headers=headers1)
    assert update_res.status_code == 200
    assert update_res.json()["username"] == new_name
    
    # 4. Zmień login Usera 2 na "Blocker" (żeby zająć nazwę)
    login_res2 = client.post("/api/v1/auth/login", data={"username": user2_data["email"], "password": user2_data["password"]})
    token2 = login_res2.json()["access_token"]
    headers2 = {"Authorization": f"Bearer {token2}"}
    client.patch("/api/v1/users/me/username", json={"username": "Blocker"}, headers=headers2)
    
    # 5. User 1 próbuje zmienić login na "Blocker" (KONFLIKT + SUGESTIE)
    conflict_res = client.patch("/api/v1/users/me/username", json={"username": "Blocker"}, headers=headers1)
    assert conflict_res.status_code == 409
    
    error_detail = conflict_res.json()["detail"]
    assert error_detail["message"] == "Username already taken"
    assert "suggestions" in error_detail
    assert len(error_detail["suggestions"]) > 0
    # Upewniamy się, że sugestie faktycznie bazują na wpisanym słowie
    assert error_detail["suggestions"][0].startswith("Blocker")
# ============================================================================


