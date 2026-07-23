from sqlalchemy import Column, Integer, String, Boolean, Float, DateTime, Index
from sqlalchemy.sql import func
from datetime import datetime, timezone
from src.db.database import Base

class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True, nullable=False)
    
    content = Column(String(500), nullable=False)
    is_completed = Column(Boolean, default=False, nullable=False)
    
    # Magia sortowania: Float pozwala na wstawianie elementów "pomiędzy" bez zmiany pozostałych
    position = Column(Float, nullable=False)
    
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    # Optymalizacja pod najczęstsze zapytanie: "daj zadania usera X, posortowane po pozycji"
    __table_args__ = (
        Index('ix_tasks_user_position', 'user_id', 'position'),
    )