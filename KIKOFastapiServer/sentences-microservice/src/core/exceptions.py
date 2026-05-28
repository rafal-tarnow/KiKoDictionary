from fastapi import Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from src.core.config import settings

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
            message = f"Text in field '{field}' is too long. Current limit is {settings.CURRENT_MAX_CHARS} characters."
            
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