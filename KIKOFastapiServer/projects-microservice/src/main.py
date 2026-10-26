from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.api.health import health_router
from src.api.v1.router import api_router
from src.core.config import settings
from src.core.exception_handlers import register_exception_handlers
from src.db.session import engine


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    # Schemat bazy tworzy i aktualizuje Alembic (`alembic upgrade head`), nie aplikacja.
    yield
    await engine.dispose()


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.PROJECT_NAME,
        version=settings.VERSION,
        description="Projects with ordered tasks (two-level TODO) for the Maia / English Learner app.",
        lifespan=lifespan,
    )

    if settings.BACKEND_CORS_ORIGINS:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=settings.BACKEND_CORS_ORIGINS,
            # Autoryzacja przez naglowek Bearer, nie przez cookies
            allow_credentials=False,
            allow_methods=["*"],
            allow_headers=["*"],
        )

    register_exception_handlers(app)
    app.include_router(health_router)
    app.include_router(api_router, prefix=settings.API_V1_PREFIX)

    @app.get("/", tags=["Health & Operations"], include_in_schema=False)
    async def root() -> dict[str, str]:
        return {"status": "ok", "service": settings.PROJECT_NAME}

    return app


app = create_app()


if __name__ == "__main__":
    uvicorn.run("src.main:app", host="127.0.0.1", port=8005, reload=True)
