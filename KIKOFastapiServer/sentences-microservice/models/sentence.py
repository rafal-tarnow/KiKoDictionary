from sqlalchemy import Column, Integer, String, DateTime
from database import Base
from datetime import datetime

class Sentence(Base):
    __tablename__ = "sentences"
    
    id = Column(Integer, primary_key=True, index=True)
    sentence = Column(String, index=True)
    language = Column(String, index=True)
    translation = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)