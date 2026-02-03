from logging.config import fileConfig
from sqlalchemy.ext.asyncio import create_async_engine
from alembic import context
from src.db.models.user import Base  # Importuj klasę Base z modeli
from src.core.config import settings  # Importuj ustawienia z DATABASE_URL
from src.db.models.refresh_token import RefreshToken

# this is the Alembic Config object, which provides
# access to the values within the .ini file in use.
config = context.config

# Interpret the config file for Python logging.
# This line sets up loggers basically.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# add your model's MetaData object here
# for 'autogenerate' support
target_metadata = Base.metadata

def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = settings.DATABASE_URL
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()

async def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    connectable = create_async_engine(settings.DATABASE_URL, echo=True)

    async with connectable.connect() as connection:
        await connection.run_sync(
            lambda sync_conn: context.configure(
                connection=sync_conn,
                target_metadata=target_metadata,
                render_as_batch=True
            )
        )

        async with context.begin_transaction():
            await connection.run_sync(lambda sync_conn: context.run_migrations())

if context.is_offline_mode():
    run_migrations_offline()
else:
    import asyncio
    asyncio.run(run_migrations_online())