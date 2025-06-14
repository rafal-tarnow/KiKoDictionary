from fastapi import FastAPI
from contextlib import asynccontextmanager
from src.api.v1.endpoints import auth, users
from src.db.models.user import Base
from src.db.session import engine

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield

app = FastAPI(
    title="Users Service",
    description="API for User Management and Authentication",
    version="1.0.0",
    lifespan=lifespan
)

app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/v1/users", tags=["Users"])

@app.get("/", tags=["Health Check"])
async def root():
    return {"status": "ok"}