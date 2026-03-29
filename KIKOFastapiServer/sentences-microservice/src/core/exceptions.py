# <=== CAŁKOWICIE NOWY PLIK: Profesjonalna obsługa wyjątków ===>
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
        
        # Tłumaczymy techniczne błędy Pydantic na biznesowe komunikaty UI
        if error.get("type") == "string_too_long":
            message = f"Tekst w polu '{field}' jest za długi. Obecny limit to {settings.CURRENT_MAX_CHARS} znaków."
            
        errors.append({
            "field": field,
            "message": message,
            "type": error.get("type")
        })

    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": "Validation Error",
            "message": "Przekazane dane nie spełniają wymagań (np. są zbyt długie).",
            "details": errors
        }
    )