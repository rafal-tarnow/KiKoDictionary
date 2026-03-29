import os
from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    PROJECT_NAME: str = "Maia Sentences Microservice"
    VERSION: str = "1.0.0"

    # ================= ZMIANA: JWT Settings =================
    SECRET_KEY: str = os.getenv("SECRET_KEY", "Z9X8v5y7_kJqP3mW2nL4rT6uY8iO0pQ2xR5tV7wU9")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    
    # <=== NOWE: Konfiguracja limitów znaków ===>
    # Trzymamy tu przyszłe limity, żeby architektura była gotowa
    MAX_CHARS_FREE: int = 150
    MAX_CHARS_PREMIUM: int = 569
    # Na ten moment wymuszamy darmowy limit globalnie
    CURRENT_MAX_CHARS: int = MAX_CHARS_FREE 
    # ========================================================

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True

settings = Settings()