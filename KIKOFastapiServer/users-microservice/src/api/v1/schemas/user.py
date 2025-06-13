from pydantic import BaseModel, EmailStr
from typing import Optional
from uuid import UUID
from datetime import datetime
from src.db.models.user import AccountType

# Base properties shared by all user schemas
class UserBase(BaseModel):
    email: EmailStr
    username: str

# Properties to receive via API on creation
class UserCreate(UserBase):
    password: str
    captcha_id: str
    captcha_answer: str

# Properties to return to the client
class UserPublic(BaseModel):
    id: UUID
    username: str
    email: EmailStr
    account_type: AccountType
    subscription_expires_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True # Pydantic v2