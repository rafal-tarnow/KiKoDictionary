from pydantic import BaseModel, EmailStr, field_validator, ConfigDict, Field
from typing import Optional
from uuid import UUID
from datetime import datetime
from src.db.models.user import AccountRole, AccountSubscription
import re  # <--- WAŻNE: Dodaj ten import

class UserBase(BaseModel):
    email: EmailStr
    username: str

    @field_validator("username")
    @classmethod
    def validate_username(cls, value: str) -> str:
        if not value or value.isspace():
            raise ValueError("The username cannot be empty or consist only of whitespace.")
        if value != value.strip():
            raise ValueError("The username cannot contain spaces at the beginning or end.")
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