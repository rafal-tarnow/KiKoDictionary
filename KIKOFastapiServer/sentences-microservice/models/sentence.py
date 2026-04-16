from sqlalchemy import Column, Integer, String, DateTime
from database import Base
from datetime import datetime, timezone
from src.core.config import settings

class Sentence(Base):
    __tablename__ = "sentences"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True, nullable=False)
    
    # ================= [ZMIANA 1]: Nowe nazewnictwo pól =================
    # 'original_text' zastępuje 'sentence'
    # 'translated_text' zastępuje 'translation'
    original_text = Column(String(settings.MAX_CHARS_PREMIUM), index=True, nullable=False, default="")
    translated_text = Column(String(settings.MAX_CHARS_PREMIUM), nullable=False, default="")
    
    # Rozbicie języka na źródłowy i docelowy
    source_language = Column(String(10), index=True, nullable=False, default="en")
    target_language = Column(String(10), index=True, nullable=False, default="en")
    # ====================================================================
    
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))