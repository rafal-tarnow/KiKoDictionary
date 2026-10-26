import logging

from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from sqlalchemy.exc import OperationalError

from src.core.exceptions import AppError, AuthenticationError

logger = logging.getLogger(__name__)


async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    headers = {"WWW-Authenticate": "Bearer"} if isinstance(exc, AuthenticationError) else None
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail, "error_code": exc.error_code},
        headers=headers,
    )


async def db_operational_error_handler(request: Request, exc: OperationalError) -> JSONResponse:
    # Ten sam kontrakt bledow co w auth-microservice (frontend juz go tlumaczy)
    logger.error("Database OperationalError: %s", exc)
    if "database is locked" in str(exc):
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={
                "detail": "Database error: Resource is locked. Service temporarily unavailable.",
                "error_code": "DB_LOCKED",
            },
        )
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Database error: Internal operation failed.", "error_code": "DB_ERROR"},
    )


def register_exception_handlers(app: FastAPI) -> None:
    app.add_exception_handler(AppError, app_error_handler)
    app.add_exception_handler(OperationalError, db_operational_error_handler)
