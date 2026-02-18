from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import Response, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.exc import OperationalError

from src.core.config import settings
from src.api.v1.routers import auth
from src.api.v1.routers import test
from src.db.models.user import Base
from src.db.models.refresh_token import RefreshToken
from src.db.models.password_reset import PasswordResetToken
from src.db.session import engine
from src.api.v1.routers.health import health_router

import yaml

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic: Create database tables
    async with engine.begin() as conn:
        # await conn.run_sync(Base.metadata.drop_all)  # Uncomment to reset DB if needed
        await conn.run_sync(Base.metadata.create_all)
    yield
    # Shutdown logic (optional): Add cleanup tasks here if needed
    # Example: await engine.dispose() to close the database connection
    pass

app = FastAPI(
    title="My Users Service", 
    description="API for User Management and Authentication", 
    version="1.0.0",
    lifespan=lifespan
    )


@app.exception_handler(OperationalError)
async def db_connection_handler(request: Request, exc: OperationalError):
    # Log dla Ciebie w konsoli
    print(f"LOG: Database OperationalError caught: {exc}")

    # Przypadek 1: Baza zablokowana (SQLite Lock)
    if "database is locked" in str(exc):
        return JSONResponse(
            status_code=503, 
            content={
                # Tutaj dodajemy jasną informację, że to wina bazy
                "detail": "Database error: Resource is locked. Service temporarily unavailable.",
                "error_code": "DB_LOCKED"
            }
        )
    
    # Przypadek 2: Inne błędy (np. zerwane połączenie, błąd składni SQL, brak serwera)
    return JSONResponse(
        status_code=500,
        content={
            # Tutaj też jasne info o bazie
            "detail": "Database error: Internal operation failed.",
            "error_code": "DB_ERROR"
        }
    )


# <--- 2. Konfiguracja Middleware (PRO)
# Dodajemy middleware TYLKO JEŚLI zdefiniowano dozwolone domeny.
# Jeśli lista jest pusta -> CORS nie działa -> Bezpieczeństwo zachowane (blokada wszystkiego z zewnątrz).
if settings.BACKEND_CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[str(origin) for origin in settings.BACKEND_CORS_ORIGINS],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

app.include_router(auth.router)
app.include_router(test.router)
app.include_router(health_router, prefix="/health", tags=["Health & Operations"])


@app.get("/docs.yaml")
async def yaml_docs():
    try:
        openapi_schema = app.openapi()
        yaml_content = yaml.dump(openapi_schema, sort_keys=False)
        return Response(
            content=yaml_content,
            media_type="application/yaml",
            headers={"Content-Disposition": "attachment; filename=docs.yaml"}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating YAML: {str(e)}")


@app.get("/", tags=['Health Check'])
async def root():
    return {"status": "ok"}