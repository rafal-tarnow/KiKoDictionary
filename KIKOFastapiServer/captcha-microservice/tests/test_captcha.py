import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from src.main import app
from src.database import SessionLocal, engine
from src.database.models import Base, Captcha
from src.database.repository import CaptchaRepository

@pytest.fixture(scope="module")
def test_client():
    # Tworzenie tabel w bazie przed testami
    Base.metadata.create_all(bind=engine)
    client = TestClient(app)
    yield client
    # Usuwanie tabel po testach
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def db():
    # Tworzenie sesji bazy danych dla każdego testu
    db = SessionLocal()
    yield db
    db.close()

@pytest.mark.asyncio
async def test_generate_captcha(test_client):
    # Test generowania CAPTCHA
    response = test_client.get("/api/v1/captcha")
    assert response.status_code == 200
    data = response.json()
    
    # Sprawdzanie struktury odpowiedzi
    assert "id" in data
    assert "image" in data
    assert data["image"].startswith("data:image/png;base64,")
    assert "created_at" in data
    assert "text" not in data  # Tekst nie powinien być zwracany
    
    # Sprawdzanie, czy CAPTCHA została zapisana w bazie
    db = SessionLocal()
    captcha = db.query(Captcha).filter(Captcha.id == data["id"]).first()
    assert captcha is not None
    assert len(captcha.text) == 6  # Domyślna długość CAPTCHA
    db.close()

@pytest.mark.asyncio
async def test_verify_captcha(test_client, db: Session):
    # Najpierw generujemy CAPTCHA
    response = test_client.get("/api/v1/captcha")
    assert response.status_code == 200
    captcha_data = response.json()
    captcha_id = captcha_data["id"]
    
    # Pobieramy tekst CAPTCHA z bazy danych
    captcha = db.query(Captcha).filter(Captcha.id == captcha_id).first()
    assert captcha is not None
    correct_text = captcha.text
    
    # Test weryfikacji z poprawnym tekstem
    verify_response = test_client.post(
        "/api/v1/captcha/verify",
        json={"id": captcha_id, "text": correct_text}
    )
    assert verify_response.status_code == 200
    assert verify_response.json() == {"is_valid": True}
    
    # Test weryfikacji z niepoprawnym tekstem
    verify_response = test_client.post(
        "/api/v1/captcha/verify",
        json={"id": captcha_id, "text": "WRONG"}
    )
    assert verify_response.status_code == 200
    assert verify_response.json() == {"is_valid": False}
    
    # Test weryfikacji z nieistniejącym ID
    verify_response = test_client.post(
        "/api/v1/captcha/verify",
        json={"id": 9999, "text": "ANY"}
    )
    assert verify_response.status_code == 404
    assert "Captcha not found" in verify_response.json()["detail"]

@pytest.mark.asyncio
async def test_get_captcha(test_client, db: Session):
    # Generujemy CAPTCHA
    response = test_client.get("/api/v1/captcha")
    assert response.status_code == 200
    captcha_id = response.json()["id"]
    
    # Test pobierania CAPTCHA
    response = test_client.get(f"/api/v1/captcha/{captcha_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == captcha_id
    assert data["image"] == ""  # Obrazek nie jest zwracany
    assert "created_at" in data
    assert "text" not in data
    
    # Test pobierania nieistniejącej CAPTCHA
    response = test_client.get("/api/v1/captcha/9999")
    assert response.status_code == 404
    assert "Captcha not found" in response.json()["detail"]