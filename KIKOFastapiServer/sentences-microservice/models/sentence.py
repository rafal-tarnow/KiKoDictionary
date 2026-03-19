from sqlalchemy import Column, Integer, String, DateTime
from database import Base
from datetime import datetime, timezone

class Sentence(Base):
    __tablename__ = "sentences"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # ================= ZMIANA: Powiązanie zdania z użytkownikiem =================
    # Baza sentences nie wie o istnieniu bazy Auth, więc nie ma tu klucza obcego (ForeignKey).
    # Przechowujemy po prostu stringa (UUID) wskazującego na właściciela.
    user_id = Column(String, index=True, nullable=False)
    # =============================================================================
    
    sentence = Column(String, index=True)
    language = Column(String, index=True)
    translation = Column(String)
    
    # ================= ZMIANA: Spójność czasowa z Auth Service =================
    # Wymuszamy czas świadomy stref czasowych (UTC)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))