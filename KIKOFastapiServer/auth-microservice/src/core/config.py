import os
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

load_dotenv()

class Settings(BaseSettings):
    VERSION: str = "1.0.0"
    CAPTCHA_SERVICE_URL: str = os.getenv("CAPTCHA_SERVICE_URL", "http://127.0.0.1:8001/api/v1") 
    # JWT Settings
    SECRET_KEY: str = os.getenv("SECRET_KEY", "Z9X8v5y7_kJqP3mW2nL4rT6uY8iO0pQ2xR5tV7wU9")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))
    REFRESH_TOKEN_EXPIRE_DAYS: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", 7))

    # Database Settings
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./users.db")                                        

settings = Settings()