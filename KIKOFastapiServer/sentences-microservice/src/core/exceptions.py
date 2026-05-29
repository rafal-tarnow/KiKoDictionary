from fastapi import Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from src.core.config import settings


# --- NOWY WYJĄTEK BIZNESOWY ---
class TierLimitExceededException(Exception):
    def __init__(self, field: str, limit: int):
        self.field = field
        self.limit = limit

def tier_limit_exception_handler(request: Request, exc: TierLimitExceededException) -> JSONResponse:
    """
    Obsługuje błąd biznesowy, gdy user free przekracza limit.
    Struktura błędu jest spójna z Pydantic (RequestValidationError).
    """
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": "Plan Limit Exceeded",
            "message": "Please upgrade to PRO to use longer texts.",
            "details": [{
                "field": exc.field,
                "message": f"Text is too long for your current plan. Limit is {exc.limit} characters.",
                "type": "tier_limit_exceeded"
            }]
        }
    )


def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    """
    Przechwytuje błędy walidacji (np. gdy ktoś przekroczy 150 znaków) 
    i formatuje je do czytelnego, biznesowego JSONa dla frontendu.
    """
    errors = []
    for error in exc.errors():
        field = error.get("loc")[-1] if error.get("loc") else "unknown"
        message = error.get("msg")
        
        # ================= [ZMIANA]: Język Angielski =================
        if error.get("type") == "string_too_long":
            message = f"Text in field '{field}' is too long. The absolute system limit is {settings.MAX_CHARS_PREMIUM} characters."
            
        errors.append({
            "field": field,
            "message": message,
            "type": error.get("type")
        })

    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": "Validation Error",
            "message": "Provided data does not meet requirements.", # <--- Tutaj też po angielsku
            "details": errors
        }
    )