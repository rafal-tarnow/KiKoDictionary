from fastapi import FastAPI
from src.api.v1.endpoints import auth, users
from src.db.models.user import Base
from src.db.session import engine

app = FastAPI(
    title="Users Service",
    description="API for User Management and Authentication",
    version="1.0.0"
)

# Create DB tables on startup
@app.on_event("startup")
async def on_startup():
    async with engine.begin() as conn:
        # await conn.run_sync(Base.metadata.drop_all) # Use this to reset db
        await conn.run_sync(Base.metadata.create_all)

# Include API v1 routers
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/v1/users", tags=["Users"])

@app.get("/", tags=["Health Check"])
async def root():
    return {"status": "ok"}