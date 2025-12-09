from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from src.api.endpoints.v1.endpoints import router as v1_router
from src.api.endpoints.health import health_router
from src.database.models import Base
from src.database import engine
from src.core.config import settings

app = FastAPI(
    title="CAPTCHA Microservice",
    version="1.0.0",
    docs_url="/api/v1/docs",
    redoc_url="/api/v1/redoc"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create database tables
Base.metadata.create_all(bind=engine)

# Include API routes
app.include_router(v1_router, prefix="/api/v1")

# Include health router
app.include_router(health_router, prefix="/health", tags=["Health & Operations"])

@app.on_event("startup")
async def startup_event():
    # Initialize any required resources
    pass

@app.on_event("shutdown")
async def shutdown_event():
    # Cleanup resources
    pass