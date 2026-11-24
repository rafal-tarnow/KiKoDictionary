import os

# Baza w pamięci - musi być ustawiona przed importem aplikacji (config czyta ją przy imporcie),
# inaczej src.main utworzyłby plik captcha.db w katalogu roboczym.
os.environ["DATABASE_URL"] = "sqlite://"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import create_engine  # noqa: E402
from sqlalchemy.orm import sessionmaker  # noqa: E402
from sqlalchemy.pool import StaticPool  # noqa: E402

from src.database.models import Base  # noqa: E402
from src.dependencies import get_db  # noqa: E402
from src.main import app  # noqa: E402


@pytest.fixture
def db_session_factory():
    # Świeża baza dla każdego testu; StaticPool = jedno połączenie, wspólne dla API i testu
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    Base.metadata.create_all(bind=engine)
    yield sessionmaker(bind=engine, autocommit=False, autoflush=False)
    engine.dispose()


@pytest.fixture
def client(db_session_factory):
    def override_get_db():
        db = db_session_factory()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
