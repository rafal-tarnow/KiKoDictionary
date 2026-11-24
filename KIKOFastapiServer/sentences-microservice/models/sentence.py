from sqlalchemy import Column, Integer, String, DateTime, Float, Index
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
    
    # [ZMIANA]: Dodałem index=True dla pojedynczego sortowania
    created_at = Column(DateTime(timezone=True), index=True, default=lambda: datetime.now(timezone.utc))

    # Ręczna kolejność na liście "My Sentences" (drag & drop, "na początek" / "na koniec").
    # Mniejsza wartość = wyżej na liście. Float pozwala wstawić zdanie "pomiędzy" dwa inne
    # bez przenumerowania pozostałych (patrz crud/sentence_ordering.py).
    position = Column(Float, nullable=False, server_default="0")

    # ================= [NOWE - PRODUKCJA]: Indeks Złożony =================
    # Baza danych stworzy specjalne drzewo zoptymalizowane dokładnie pod zapytanie:
    # "daj mi zdania z angielskiego na polski, posortowane od najnowszego"
    __table_args__ = (
        Index('ix_sentences_lang_date', 'source_language', 'target_language', 'created_at'),
        # Najczęstsze zapytanie "My Sentences": zdania usera X posortowane po pozycji
        Index('ix_sentences_user_position', 'user_id', 'position'),
    )
    # =======================================================================