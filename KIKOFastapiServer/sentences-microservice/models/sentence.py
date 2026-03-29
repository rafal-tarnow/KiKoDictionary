from sqlalchemy import Column, Integer, String, DateTime
from database import Base
from datetime import datetime, timezone
from src.core.config import settings # <=== ZMIANA: import

class Sentence(Base):
    __tablename__ = "sentences"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True, nullable=False)
    
    # <=== ZMIANA: Przygotowujemy bazę pod maksymalny rozmiar Premium! 
    # Nie powstaną problemy z migracją DB w przyszłości.
    sentence = Column(String(settings.MAX_CHARS_PREMIUM), index=True, default="")
    language = Column(String(50), index=True, default="")
    translation = Column(String(settings.MAX_CHARS_PREMIUM), default="")
    # =============================================================================
    
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))