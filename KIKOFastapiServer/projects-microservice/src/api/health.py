import logging

from fastapi import APIRouter, status
from fastapi.responses import JSONResponse
from sqlalchemy import text

from src.api.deps import SessionDep, SettingsDep
from src.schemas import HealthCheckResponse

logger = logging.getLogger(__name__)

health_router = APIRouter(prefix="/health", tags=["Health & Operations"])


@health_router.get(
    "/live",
    response_model=HealthCheckResponse,
    summary="Liveness Probe",
    description="Sprawdza czy aplikacja jest uruchomiona. Nie sprawdza zaleznosci.",
)
async def liveness_probe(settings: SettingsDep) -> HealthCheckResponse:
    return HealthCheckResponse(status="ok", version=settings.VERSION)


@health_router.get(
    "/ready",
    response_model=HealthCheckResponse,
    summary="Readiness Probe",
    description="Sprawdza czy serwis moze obslugiwac ruch (polaczenie z baza).",
    responses={status.HTTP_503_SERVICE_UNAVAILABLE: {"model": HealthCheckResponse}},
)
async def readiness_probe(session: SessionDep, settings: SettingsDep) -> HealthCheckResponse | JSONResponse:
    try:
        await session.execute(text("SELECT 1"))
    except Exception:  # noqa: BLE001 - kazdy blad bazy = serwis niegotowy
        logger.exception("Readiness check failed")
        body = HealthCheckResponse(status="error", version=settings.VERSION, components={"database": "down"})
        return JSONResponse(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, content=body.model_dump())
    return HealthCheckResponse(status="ok", version=settings.VERSION, components={"database": "operational"})
