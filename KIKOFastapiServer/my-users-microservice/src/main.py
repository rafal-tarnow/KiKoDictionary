from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from fastapi.responses import Response
from src.api.v1.routers import auth
from src.api.v1.routers import test
from src.db.models.user import Base
from src.db.models.refresh_token import RefreshToken
from src.db.session import engine
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


app.include_router(auth.router)
app.include_router(test.router)


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