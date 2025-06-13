from fastapi.testclient import TestClient
import pytest
from src.main import app

client = TestClient(app)

def test_not_found():
    response = client.get("/invalid-endpoint")
    assert response.status_code == 404
    assert response.json() == {"detail": "Not Found"}
    
def test_get_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/json"
    assert response.json() == {"status": "ok"}

@pytest.fixture
def valid_register_data():
    return {
        "email" : "user2@example.com",
        "username" : "john2_doe",
        "password" : "secure123"
    }

def test_post_register_user(valid_register_data):
    response = client.post("/api/v1/auth/register", json=valid_register_data)
    assert response.status_code == 201
    assert response.headers["content-type"] == "application/json"
    response_json = response.json()
    assert "id" in response_json
    assert response_json["username"] == valid_register_data["username"]
    assert response_json["email"] == valid_register_data["email"]

@pytest.mark.parametrize("invalid_email", [
    "invalid-email",
    "user@",
    "@domain.com",
    "user@domain",
    "user.domain.com",
    "user@.com"
])

def test_post_register_user_invalid_email(valid_register_data, invalid_email):
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

@pytest.mark.parametrize("invalid_username, expected_error_msg", [
    ("", "Value error, The username cannot be empty or consist only of whitespace."),
    ("   ", "Value error, The username cannot be empty or consist only of whitespace."),
    ("  john", "Value error, The username cannot contain spaces at the beginning or end."),
    ("john  ", "Value error, The username cannot contain spaces at the beginning or end."),
])

def test_post_register_user_invalid_username(valid_register_data, invalid_username, expected_error_msg):
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