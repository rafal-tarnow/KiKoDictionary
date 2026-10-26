import os

# Konfiguracja MUSI byc ustawiona przed importem aplikacji (Settings czytane przy imporcie).
# Zmienne srodowiskowe maja pierwszenstwo przed plikiem .env.
os.environ["SECRET_KEY"] = "test-secret-key"
os.environ["ALGORITHM"] = "HS256"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite://"

from collections.abc import AsyncIterator  # noqa: E402

import pytest  # noqa: E402
from httpx import ASGITransport, AsyncClient  # noqa: E402
from sqlalchemy.ext.asyncio import AsyncEngine  # noqa: E402
from sqlalchemy.pool import StaticPool  # noqa: E402

import src.db.models  # noqa: E402,F401
from src.db.base import Base  # noqa: E402
from src.db.session import create_engine, create_session_factory, get_db_session  # noqa: E402
from src.main import app  # noqa: E402
from tests.factories import USER_A, USER_B, auth_header  # noqa: E402


@pytest.fixture
async def engine() -> AsyncIterator[AsyncEngine]:
    # Baza w pamieci, swieza dla kazdego testu. StaticPool = jedno polaczenie,
    # inaczej kazde nowe polaczenie widzialoby pusta baze.
    test_engine = create_engine("sqlite+aiosqlite://", poolclass=StaticPool)
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield test_engine
    await test_engine.dispose()


@pytest.fixture
async def client(engine: AsyncEngine) -> AsyncIterator[AsyncClient]:
    session_factory = create_session_factory(engine)

    async def override_get_db_session():
        async with session_factory() as session:
            yield session

    app.dependency_overrides[get_db_session] = override_get_db_session
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture
def user_a() -> dict[str, str]:
    return auth_header(USER_A)


@pytest.fixture
def user_b() -> dict[str, str]:
    return auth_header(USER_B)
