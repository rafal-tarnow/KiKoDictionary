from pydantic import BaseModel, EmailStr, field_validator, ConfigDict, Field
from typing import Optional, Any
from uuid import UUID
from datetime import datetime
from src.db.models.user import AccountRole, AccountSubscription
from src.api.v1.schemas.user_profile import UserProfilePublic
import re



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

    # Używamy mode='before', żeby naprawić dane zanim Pydantic zacznie marudzić
    @field_validator("email", mode="before")
    @classmethod
    def case_insensitive_email(cls, v: Any) -> Any:
        # Sprawdzamy czy to string, żeby nie wysadzić serwera
        # gdyby ktoś złośliwie przysłał int albo tablicę w polu email.
        if isinstance(v, str):
            return v.lower()
        return v


class UserCreate(UserBase):
    # ZMIANA: Usuwamy 'min_length=8' stąd, żeby uniknąć błędu "String should have..."
    # Zostawiamy description dla dokumentacji
    password: str = Field(..., description="Password must be at least 8 characters long")

    @field_validator("password")
    @classmethod
    def validate_password_content(cls, value: str) -> str:
        # 1. ZMIANA: Dodajemy walidację długości TUTAJ, żeby mieć własny komunikat
        if len(value) < 8:
            raise ValueError("Password must be at least 8 characters long")

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
    username: str
    account_role: AccountRole
    account_subscription: AccountSubscription
    subscription_expires_at: Optional[datetime] = None
    created_at: datetime
    # --- [ZMIANA]: Zwracamy zagnieżdżony profil ---
    profile: Optional[UserProfilePublic] = None 

    model_config = ConfigDict(from_attributes=True)


class UserUpdateUsername(BaseModel):
    username: str = Field(..., description="Username must be 3-30 characters.")

    @field_validator("username")
    @classmethod
    def validate_username_security(cls, value: str) -> str:
        if len(value) < 3:
            raise ValueError("Username must be at least 3 characters long.")
        if len(value) > 30:
            raise ValueError("Username cannot be longer than 30 characters.")
        if not re.match(USERNAME_REGEX, value):
            raise ValueError("Username can only contain letters, numbers, underscores (_), and hyphens (-).")
        if value.lower() in RESERVED_USERNAMES:
            raise ValueError("This username is reserved and cannot be used.")
        if "@" in value:
             raise ValueError("Username cannot contain '@' symbol.")
        if "__" in value or "--" in value:
            raise ValueError("Username cannot contain consecutive underscores or hyphens.")
        return value
