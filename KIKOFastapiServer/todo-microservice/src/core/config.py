from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str = "Maia TODO Microservice"
    VERSION: str = "1.0.0"
    
    # DB & Auth
    DATABASE_URL: str
    SECRET_KEY: str
    ALGORITHM: str
    
    # Konfiguracja algorytmu sortowania (odstęp między nowymi zadaniami)
    POSITION_STEP: float = 1000.0

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

settings = Settings()