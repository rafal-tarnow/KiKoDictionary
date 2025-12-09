from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    PROJECT_NAME: str = "CAPTCHA Microservice"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    DATABASE_URL: str = "sqlite:///./captcha.db"
    ALLOWED_ORIGINS: List[str] = ["*"]
    CAPTCHA_LENGTH: int = 6
    CAPTCHA_WIDTH: int = 200
    CAPTCHA_HEIGHT: int = 80
    CACHE_TTL: int = 300  # 5 minutes in seconds

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True

settings = Settings()