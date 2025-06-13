import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_register_user_success(client: AsyncClient):
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "test@example.com",
            "username": "testuser",
            "password": "testpassword",
            "captcha_id": "some_id",
            "captcha_answer": "VALID" # This will pass the mock
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "test@example.com"
    assert data["username"] == "testuser"
    assert "id" in data
    assert data["account_type"] == "FREE"

@pytest.mark.asyncio
async def test_register_user_invalid_captcha(client: AsyncClient):
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "test2@example.com",
            "username": "testuser2",
            "password": "testpassword",
            "captcha_id": "some_id",
            "captcha_answer": "INVALID" # This will fail the mock
        },
    )
    assert response.status_code == 400
    assert response.json()["detail"] == "Invalid CAPTCHA"

@pytest.mark.asyncio
async def test_register_user_duplicate_email(client: AsyncClient):
    # First registration (should succeed)
    await client.post(
        "/api/v1/auth/register",
        json={
            "email": "duplicate@example.com",
            "username": "duplicate_user",
            "password": "testpassword",
            "captcha_id": "some_id",
            "captcha_answer": "VALID"
        },
    )
    # Second registration with same email
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "duplicate@example.com",
            "username": "another_user",
            "password": "testpassword",
            "captcha_id": "some_id",
            "captcha_answer": "VALID"
        },
    )
    assert response.status_code == 409
    assert response.json()["detail"] == "Email already registered"