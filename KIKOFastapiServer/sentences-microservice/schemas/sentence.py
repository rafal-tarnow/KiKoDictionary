from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from typing import Optional, List
from src.core.config import settings

class SentenceCreate(BaseModel):
    # ZMIANA: Zezwalamy na przepuszczenie do serwisu maksymalnej wartości z bazy danych
    original_text: str = Field(default="", min_length=0, max_length=settings.MAX_CHARS_PREMIUM)
    translated_text: str = Field(default="", min_length=0, max_length=settings.MAX_CHARS_PREMIUM)
    # ISO 639-1 to zazwyczaj 2 litery (np. 'pl', 'en'), ew. 'en-US' (5 znaków). Max 10 to bezpieczny margines.
    source_language: str = Field(default="en", min_length=2, max_length=10)
    target_language: str = Field(default="en", min_length=2, max_length=10)

class SentenceUpdate(BaseModel):
    # Opcjonalne pola do edycji. Jeśli None - znaczy, że nie ruszamy tego pola.
    original_text: Optional[str] = Field(None, min_length=0, max_length=settings.MAX_CHARS_PREMIUM)
    translated_text: Optional[str] = Field(None, min_length=0, max_length=settings.MAX_CHARS_PREMIUM)
    source_language: Optional[str] = Field(None, min_length=2, max_length=10)
    target_language: Optional[str] = Field(None, min_length=2, max_length=10)


class Sentence(BaseModel):
    id: int
    original_text: str
    translated_text: str
    source_language: str
    target_language: str
    created_at: datetime
    
    # ================= [NOWE - PRODUKCJA 3]: Pydantic V2 Standard =================
    model_config = ConfigDict(from_attributes=True)
    # Zastąpiło to stare "class Config: from_attributes = True"
    # ==============================================================================


# ================= [NOWE - PRODUKCJA]: Schematy Paginacji =================
class PaginatedSentences(BaseModel):
    data: List[Sentence]
    page: int
    per_page: int
    total: int
    total_pages: int
    is_authenticated: Optional[bool] = None # Zwracane tylko na /community
# ==========================================================================
