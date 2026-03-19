import os
from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    PROJECT_NAME: str = "Maia Sentences Microservice"
    VERSION: str = "1.0.0"

    # ================= ZMIANA: JWT Settings =================
    # Te same wartości co w Auth Service
    SECRET_KEY: str = os.getenv("SECRET_KEY", "Z9X8v5y7_kJqP3mW2nL4rT6uY8iO0pQ2xR5tV7wU9")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    # ========================================================

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True

settings = Settings()