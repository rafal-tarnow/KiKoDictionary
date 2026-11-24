import uuid
from datetime import datetime

from pydantic import BaseModel, Field

# class CaptchaCreate(BaseModel):
#     text: str

class CaptchaResponse(BaseModel):
    id: int
    text: str
    image: str
    created_at: datetime

#     class Config:
#         from_attributes = True

# class CaptchaVerifyRequest(BaseModel):
#     id: int
#     text: str

# class CaptchaVerifyResponse(BaseModel):
#     is_valid: bool

##############################################################3

class CaptchaChallengeResponse(BaseModel): # Zmieniony schemat dla generowania
    id: uuid.UUID = Field(default_factory=uuid.uuid4)
    image: str # Base64 data URL obrazka

class CaptchaVerifyRequest(BaseModel):
    id: uuid.UUID
    answer: str # Zmieniona nazwa pola

class CaptchaVerifyResponse(BaseModel):
    is_valid: bool