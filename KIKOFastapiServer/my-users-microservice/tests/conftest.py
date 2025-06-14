# tests/conftest.py
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from src.main import app
from src.db.session import get_db
from src.db.models.user import Base

# Create an in-memory SQLite database for tests
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"
test_engine = create_async_engine(TEST_DATABASE_URL, echo=True)
TestingSessionLocal = sessionmaker(
    autocommit=False, autoflush=False, bind=test_engine, class_=AsyncSession
)

# Override the get_db dependency to use the test database
async def override_get_db():
    async with TestingSessionLocal() as session:
        yield session

app.dependency_overrides[get_db] = override_get_db

# Create a test client fixture
@pytest.fixture
def client():
    return TestClient(app)

# Fixture to set up and tear down the database for each test
@pytest.fixture(autouse=True, scope="function")
async def setup_database():
    # Create tables before each test
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)  # Ensure clean state
        await conn.run_sync(Base.metadata.create_all)
    yield
    # Clean up after each test
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)