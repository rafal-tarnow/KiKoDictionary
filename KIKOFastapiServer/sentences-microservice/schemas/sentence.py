from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class SentenceCreate(BaseModel):
    sentence: str
    language: str
    translation: str

class SentenceUpdate(BaseModel):
    sentence: Optional[str] = None
    language: Optional[str] = None
    translation: Optional[str] = None

class Sentence(BaseModel):
    id: int
    sentence: str
    language: str
    translation: str
    created_at: datetime

    class Config:
        from_attributes = True