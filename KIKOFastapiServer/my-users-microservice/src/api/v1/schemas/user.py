from pydantic import BaseModel, EmailStr, field_validator, ConfigDict
from typing import Optional
from uuid import UUID
from datetime import datetime
from src.db.models.user import AccountRole, AccountSubscription

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
    password: str

class UserPublic(UserBase):
    id: UUID
    account_role: AccountRole
    account_subscription: AccountSubscription
    subscription_expires_at: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)