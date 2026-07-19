from pydantic_settings import BaseSettings
from typing import List
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "CAPTCHA Microservice"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # DODANO: ": str" 
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./captcha.db")
    
    ALLOWED_ORIGINS: List[str] = ["*"]
    CAPTCHA_LENGTH: int = 6
    CAPTCHA_WIDTH: int = 200
    CAPTCHA_HEIGHT: int = 80
    CACHE_TTL: int = 300  # 5 minutes in seconds
    
    # ================= ZMIANA: Flaga konfiguracyjna do cyfr =================
    # Domyślnie ustawiamy na True, aby generować tylko litery
    CAPTCHA_USE_DIGITS: bool = True
    # ========================================================================

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True

settings = Settings()