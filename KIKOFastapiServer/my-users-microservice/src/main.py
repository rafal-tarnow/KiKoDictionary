from contextlib import asynccontextmanager
from fastapi import FastAPI
from src.api.v1.routers import auth
from src.db.models.user import Base
from src.db.session import engine

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


app.include_router(auth.router)


@app.get("/", tags=['Health Check'])
async def root():
    return {"status": "ok"}