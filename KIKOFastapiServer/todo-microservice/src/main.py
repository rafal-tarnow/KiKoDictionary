from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from src.core.config import settings
from src.db.database import engine, Base
from src.api.routers.tasks import router as tasks_router
import uvicorn

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Automatyczne tworzenie tabel (przy dewelopmencie). 
    # Na produkcji zastąpisz to narzędziem Alembic!
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
# Inicjalizacja aplikacji - to jest to "app" z "src.main:app"
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Zmień na produkcji na URL swojej aplikacji
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(tasks_router)

@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "ok", "service": settings.PROJECT_NAME}

if __name__ == "__main__":
    # Odpalanie serwera. Parametr reload przydaje się przy pisaniu kodu.
    uvicorn.run("src.main:app", host="127.0.0.1", port=8004, reload=True)