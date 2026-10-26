from collections.abc import AsyncGenerator

from sqlalchemy import event
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine

from src.core.config import settings


def register_sqlite_pragmas(engine: AsyncEngine) -> None:
    """
    SQLite domyslnie IGNORUJE klucze obce. Bez tego `ON DELETE CASCADE`
    nie usunalby zadan razem z projektem.
    """
    if engine.dialect.name != "sqlite":
        return

    @event.listens_for(engine.sync_engine, "connect")
    def _set_sqlite_pragma(dbapi_connection, _connection_record) -> None:  # noqa: ANN001
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()


def create_engine(url: str = settings.DATABASE_URL, **kwargs) -> AsyncEngine:  # noqa: ANN003
    engine = create_async_engine(url, echo=settings.DATABASE_ECHO, **kwargs)
    register_sqlite_pragmas(engine)
    return engine


def create_session_factory(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(bind=engine, expire_on_commit=False, autoflush=False)


engine = create_engine()
AsyncSessionLocal = create_session_factory(engine)


async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session
