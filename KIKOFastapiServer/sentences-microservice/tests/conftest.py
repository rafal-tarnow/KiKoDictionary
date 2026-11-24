import os

# Konfiguracja przed importem aplikacji (database.py i config czytają ją przy imporcie).
# Baza w pamięci - testy nigdy nie dotykają prawdziwego sentences.db.
os.environ["SECRET_KEY"] = "test-secret-key"
os.environ["ALGORITHM"] = "HS256"
os.environ["DATABASE_URL"] = "sqlite://"

from datetime import datetime, timedelta, timezone  # noqa: E402

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from jose import jwt  # noqa: E402
from sqlalchemy import create_engine  # noqa: E402
from sqlalchemy.orm import sessionmaker  # noqa: E402
from sqlalchemy.pool import StaticPool  # noqa: E402

from database import Base, get_db  # noqa: E402
from main import app  # noqa: E402

USER_A = "11111111-1111-1111-1111-111111111111"
USER_B = "22222222-2222-2222-2222-222222222222"


def auth_header(user_id: str) -> dict[str, str]:
    payload = {"sub": user_id, "type": "access", "exp": datetime.now(timezone.utc) + timedelta(minutes=15)}
    return {"Authorization": f"Bearer {jwt.encode(payload, 'test-secret-key', algorithm='HS256')}"}


@pytest.fixture
def client():
    # Świeża baza na każdy test; StaticPool = jedno połączenie (inaczej każda sesja widziałaby pustą bazę)
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    Base.metadata.create_all(bind=engine)
    session_factory = sessionmaker(bind=engine, autocommit=False, autoflush=False)

    def override_get_db():
        db = session_factory()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
    engine.dispose()


@pytest.fixture
def user_a() -> dict[str, str]:
    return auth_header(USER_A)


@pytest.fixture
def user_b() -> dict[str, str]:
    return auth_header(USER_B)
