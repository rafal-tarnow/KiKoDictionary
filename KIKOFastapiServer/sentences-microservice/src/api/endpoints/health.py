from fastapi import APIRouter, status
from src.api.endpoints.schemas.health import HealthCheckResponse
from src.core.config import settings

health_router = APIRouter()

@health_router.get(
    "/live",
    response_model=HealthCheckResponse,
    status_code=status.HTTP_200_OK,
    summary="Liveness Probe",
    description="Sprawdza czy aplikacja jest uruchomiona. Nie sprawdza zależności."
)
async def liveness_probe():
    """
    Szybki check dla Kubernetesa. Jeśli to nie działa, K8s restartuje poda.
    """
    return HealthCheckResponse(
        status="ok",
        version=settings.VERSION
    )