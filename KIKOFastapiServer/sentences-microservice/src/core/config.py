import os
from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    PROJECT_NAME: str = "Maia Sentences Microservice"
    VERSION: str = "1.0.0"

    # ================= ZMIANA: JWT Settings =================
    # Brak wartosci domyslnej celowo: bez SECRET_KEY w .env / srodowisku serwis nie wystartuje.
    # Klucz musi byc identyczny jak w auth-microservice.
    SECRET_KEY: str
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    
    # <=== NOWE: Konfiguracja limitów znaków ===>
    # Trzymamy tu przyszłe limity, żeby architektura była gotowa
    MAX_CHARS_FREE: int = 150
    MAX_CHARS_PREMIUM: int = 569
    # ========================================================

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True

settings = Settings()