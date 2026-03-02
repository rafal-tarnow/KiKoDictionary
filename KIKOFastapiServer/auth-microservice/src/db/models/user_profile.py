import uuid
from sqlalchemy import Column, String, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from src.db.models.user import Base

class UserProfile(Base):
    __tablename__ = "user_profiles"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    # Opcja ondelete="CASCADE" gwarantuje, że usunięcie Usera usunie też Profil
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    
    # Przechowujemy język jako 2-literowy kod ISO 639-1 (np. 'en', 'pl', 'es')
    native_language = Column(String(2), default="en", nullable=False)
    
    # Miejsce na przyszłe ustawienia (np. cel nauki, motyw ui)
    ui_theme = Column(String, default="system", nullable=False)
    
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relacja zwrotna
    user = relationship("User", back_populates="profile")