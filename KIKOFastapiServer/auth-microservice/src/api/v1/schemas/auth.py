from pydantic import BaseModel, EmailStr, Field, field_validator
from src.api.v1.schemas.user import UserCreate  # Importujemy, żeby użyć walidatora hasła

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str = Field(..., description="New password")

    # RE-USE LOGIC: Używamy tej samej walidacji co przy rejestracji!
    @field_validator("new_password")
    @classmethod
    def validate_password(cls, v):
        return UserCreate.validate_password_content(v)