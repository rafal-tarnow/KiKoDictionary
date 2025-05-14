from sqlalchemy.orm import Session
from src.database.models import Captcha
from datetime import datetime

# class CaptchaRepository:
#     def __init__(self, db: Session):
#         self.db = db

#     def create_captcha(self, text: str) -> Captcha:
#         captcha = Captcha(text=text, created_at=datetime.utcnow())
#         self.db.add(captcha)
#         self.db.commit()
#         self.db.refresh(captcha)
#         return captcha

#     def get_captcha(self, captcha_id: int) -> Captcha:
#         return self.db.query(Captcha).filter(Captcha.id == captcha_id).first()
    
# src/database/repository.py
from datetime import datetime, timedelta, timezone
from sqlalchemy import delete

class CaptchaRepository:
    def __init__(self, db: Session):
        self.db = db

    def create_captcha_entry(self, captcha_id: str, text: str):
        # Zakładamy, że model Captcha ma pole 'id' typu String i 'text' typu String
        # oraz 'created_at'
        db_captcha = Captcha(id=captcha_id, text=text, created_at=datetime.now(timezone.utc))
        self.db.add(db_captcha)
        self.db.commit()
        # self.db.refresh(db_captcha) # Niekoniecznie potrzebne, jeśli nie zwracasz obiektu

    def get_valid_captcha_entry(self, captcha_id: str, ttl_seconds: int) -> Captcha | None:
        captcha = self.db.query(Captcha).filter(Captcha.id == captcha_id).first()
        if not captcha:
            return None

        # SPRAWDŹ TTL - Dodaj .replace(tzinfo=timezone.utc) tutaj:
        # To zapewni, że captcha.created_at będzie traktowane jako świadome UTC
        # tuż przed porównaniem, niezależnie od tego, jak zostało wczytane.
        created_at_aware = captcha.created_at.replace(tzinfo=timezone.utc)

        if datetime.now(timezone.utc) > created_at_aware + timedelta(seconds=ttl_seconds):
            self.delete_captcha_entry(captcha_id) # Usuń przeterminowaną
            return None
        return captcha

    def delete_captcha_entry(self, captcha_id: str):
        # Zakładamy, że model Captcha ma pole 'id' typu String
        stmt = delete(Captcha).where(Captcha.id == captcha_id)
        self.db.execute(stmt)
        self.db.commit()