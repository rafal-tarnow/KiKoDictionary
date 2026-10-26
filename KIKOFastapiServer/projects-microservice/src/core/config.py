from functools import lru_cache
from typing import Annotated

from pydantic import field_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict


class Settings(BaseSettings):
    """Konfiguracja serwisu czytana ze zmiennych srodowiskowych / pliku .env."""

    PROJECT_NAME: str = "Maia Projects Microservice"
    VERSION: str = "1.0.0"
    API_V1_PREFIX: str = "/api/v1"

    # --- Baza danych ---
    DATABASE_URL: str = "sqlite+aiosqlite:///./projects.db"
    DATABASE_ECHO: bool = False

    # --- JWT (musi byc zgodne z auth-microservice) ---
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    # Uzywane tylko przez Swagger UI (przycisk "Authorize")
    AUTH_TOKEN_URL: str = "http://127.0.0.1:8002/api/v1/auth/login"

    # --- CORS ---
    # NoDecode: wartosc z .env to zwykly string "a,b,c", a nie JSON
    BACKEND_CORS_ORIGINS: Annotated[list[str], NoDecode] = ["*"]

    # --- Sortowanie (Drag & Drop) ---
    # Odstep miedzy kolejnymi elementami przy dodawaniu na koniec listy
    POSITION_STEP: float = 1000.0
    # Gdy przerwa miedzy sasiadami spadnie ponizej tej wartosci, numerujemy liste od nowa
    POSITION_MIN_GAP: float = 1e-6

    # --- Limity (ochrona przed naduzyciami) ---
    MAX_PROJECTS_PER_USER: int = 200
    MAX_TASKS_PER_PROJECT: int = 1000

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=True,
    )

    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def _split_cors_origins(cls, value: str | list[str]) -> list[str]:
        if isinstance(value, str):
            return [origin.strip() for origin in value.split(",") if origin.strip()]
        return value


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
