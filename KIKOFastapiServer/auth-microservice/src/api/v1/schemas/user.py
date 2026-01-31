from pydantic import BaseModel, EmailStr, field_validator, ConfigDict, Field
from typing import Optional
from uuid import UUID
from datetime import datetime
from src.db.models.user import AccountRole, AccountSubscription
import re
from typing import Any

# Lista słów, których nie można użyć jako nazwy użytkownika
RESERVED_USERNAMES = {
    "admin", "administrator", "root", "system", "support", "help", 
    "moderator", "superuser", "guest", "api", "auth", "login", 
    "logout", "register", "dashboard", "settings", "profile"
}

# Regex: Startuje od litery, potem litery, cyfry, _ lub -. 
# Nie pozwala na _ lub - na końcu lub na początku (opcjonalnie).
# Tutaj prosta wersja: a-z, 0-9, _, -
USERNAME_REGEX = r"^[a-zA-Z0-9_-]+$"

class UserBase(BaseModel):
    email: EmailStr
    # ZMIANA: Usunięto min_length i max_length z Field(), aby uniknąć generycznych błędów Pydantic.
    # Walidacja długości odbywa się teraz w validate_username_security.
    username: str = Field(
        ..., 
        description="Username must be 3-30 characters, strictly alphanumeric, underscores or hyphens."
    )

    # Używamy mode='before', żeby naprawić dane zanim Pydantic zacznie marudzić
    @field_validator("email", mode="before")
    @classmethod
    def case_insensitive_email(cls, v: Any) -> Any:
        # Sprawdzamy czy to string, żeby nie wysadzić serwera
        # gdyby ktoś złośliwie przysłał int albo tablicę w polu email.
        if isinstance(v, str):
            return v.lower()
        return v


    @field_validator("username")
    @classmethod
    def validate_username_security(cls, value: str) -> str:
        # --- WAŻNE: NIE USUWAĆ PONIŻSZEGO BLOKU ---
        # Sprawdzamy długość ręcznie tutaj, zamiast w Field(), aby zwrócić
        # precyzyjny komunikat błędu dla Frontendu, zamiast generycznego
        # "String should have at least X characters" z Pydantic.
        if len(value) < 3:
            raise ValueError("Username must be at least 3 characters long.")
        
        if len(value) > 30:
            raise ValueError("Username cannot be longer than 30 characters.")
        # ------------------------------------------

        # 1. Sprawdzenie znaków (Regex)
        if not re.match(USERNAME_REGEX, value):
            raise ValueError("Username can only contain letters, numbers, underscores (_), and hyphens (-).")

        # 2. Sprawdzenie słów zastrzeżonych
        if value.lower() in RESERVED_USERNAMES:
            raise ValueError("This username is reserved and cannot be used.")
            
        # 3. Sprawdzenie czy nie wygląda jak email (żeby ludzie nie wpisywali tu maila)
        if "@" in value:
             raise ValueError("Username cannot contain '@' symbol.")

        # 4. Podwójne kropki/podkreślenia (opcjonalne - estetyka)
        if "__" in value or "--" in value:
            raise ValueError("Username cannot contain consecutive underscores or hyphens.")

        return value
    

class UserCreate(UserBase):
    # ZMIANA: Usuwamy 'min_length=6' stąd, żeby uniknąć błędu "String should have..."
    # Zostawiamy description dla dokumentacji
    password: str = Field(..., description="Password must be at least 6 characters long")

    @field_validator("password")
    @classmethod
    def validate_password_content(cls, value: str) -> str:
        # 1. ZMIANA: Dodajemy walidację długości TUTAJ, żeby mieć własny komunikat
        if len(value) < 6:
            raise ValueError("Password must be at least 6 characters long")

        # 2. Wymaganie: minimum jedna cyfra
        if not re.search(r"\d", value):
            raise ValueError("Password must contain at least one digit")
        
        # 3. Wymaganie: minimum jedna litera (duża lub mała)
        if not re.search(r"[a-zA-Z]", value):
            raise ValueError("Password must contain at least one letter")
            
        return value

class UserRegister(UserCreate):
    captcha_id: UUID
    captcha_answer: str
    
class UserPublic(UserBase):
    id: UUID
    account_role: AccountRole
    account_subscription: AccountSubscription
    subscription_expires_at: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)