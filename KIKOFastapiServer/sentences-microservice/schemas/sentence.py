from pydantic import BaseModel, Field # <=== ZMIANA: Import Field
from datetime import datetime
from typing import Optional
from src.core.config import settings # <=== ZMIANA: Import konfiguracji

class SentenceCreate(BaseModel):
    # <=== ZMIANA: Ustawiamy min_length=0 i max_length z konfiguracji. 
    # Używamy default="", dzięki czemu jeśli user na szybko nie wpisze tłumaczenia, 
    # pole nie wywali błędu, tylko zapisze się jako puste.
    sentence: str = Field(default="", min_length=0, max_length=settings.CURRENT_MAX_CHARS)
    language: str = Field(default="", min_length=0, max_length=50)
    translation: str = Field(default="", min_length=0, max_length=settings.CURRENT_MAX_CHARS)

class SentenceUpdate(BaseModel):
    sentence: Optional[str] = Field(None, min_length=0, max_length=settings.CURRENT_MAX_CHARS)
    language: Optional[str] = Field(None, min_length=0, max_length=50)
    translation: Optional[str] = Field(None, min_length=0, max_length=settings.CURRENT_MAX_CHARS)

class Sentence(BaseModel):
    id: int
    sentence: str
    language: str
    translation: str
    created_at: datetime

    class Config:
        from_attributes = True