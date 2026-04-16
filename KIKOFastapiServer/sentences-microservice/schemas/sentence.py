from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from src.core.config import settings

class SentenceCreate(BaseModel):
    # ================= [ZMIANA 2]: Nowe pola w schematach =================
    original_text: str = Field(default="", min_length=0, max_length=settings.CURRENT_MAX_CHARS)
    translated_text: str = Field(default="", min_length=0, max_length=settings.CURRENT_MAX_CHARS)
    
    # ISO 639-1 to zazwyczaj 2 litery (np. 'pl', 'en'), ew. 'en-US' (5 znaków). Max 10 to bezpieczny margines.
    source_language: str = Field(default="en", min_length=2, max_length=10)
    target_language: str = Field(default="en", min_length=2, max_length=10)

class SentenceUpdate(BaseModel):
    original_text: Optional[str] = Field(None, min_length=0, max_length=settings.CURRENT_MAX_CHARS)
    translated_text: Optional[str] = Field(None, min_length=0, max_length=settings.CURRENT_MAX_CHARS)
    source_language: Optional[str] = Field(None, min_length=2, max_length=10)
    target_language: Optional[str] = Field(None, min_length=2, max_length=10)

class Sentence(BaseModel):
    id: int
    original_text: str
    translated_text: str
    source_language: str
    target_language: str
    created_at: datetime
    # =====================================================================

    class Config:
        from_attributes = True