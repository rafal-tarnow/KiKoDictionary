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

    # Password Reset
    RESET_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("RESET_TOKEN_EXPIRE_MINUTES", 15))
    FRONTEND_URL: str = os.getenv("FRONTEND_URL", "http://localhost:3000")
    
    # Email Settings (przykładowe pod Gmail lub SMTP)
    SMTP_HOST: str = os.getenv("SMTP_HOST", "smtp.gmail.com")
    SMTP_PORT: int = int(os.getenv("SMTP_PORT", 587))
    SMTP_USER: str = os.getenv("SMTP_USER", "twoj-email@gmail.com")
    SMTP_PASSWORD: str = os.getenv("SMTP_PASSWORD", "twoje-haslo-aplikacji")
    # Adres e-mail, z którego system "technicznie" wysyła wiadomości.
    # To na ten adres użytkownik spróbuje odpisać, jeśli kliknie "Odpowiedz".
    # os.getenv(...) sprawdza czy w pliku .env jest klucz EMAILS_FROM_EMAIL.
    # Jeśli nie ma, używa wartości domyślnej "info@myapp.com".
    EMAILS_FROM_EMAIL: str = os.getenv("EMAILS_FROM_EMAIL", "info@myapp.com")
    # Nazwa wyświetlana (Friendly Name), którą użytkownik widzi na liście wiadomości
    # zamiast surowego adresu e-mail. Buduje to zaufanie i profesjonalny wizerunek.
    # Np. zamiast widzieć "info@myapp.com", użytkownik zobaczy "My Users Service".
    EMAILS_FROM_NAME: str = os.getenv("EMAILS_FROM_NAME", "English Learner")
    
settings = Settings()