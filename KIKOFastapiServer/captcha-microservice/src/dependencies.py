from fastapi import Depends
from sqlalchemy.orm import Session
from src.database import SessionLocal
from src.database.repository import CaptchaRepository
from src.core.captcha_generator import CaptchaGenerator
from src.core.config import settings

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_captcha_repository(db: Session = Depends(get_db)):
    return CaptchaRepository(db)

def get_captcha_generator():
    return CaptchaGenerator(
        width=settings.CAPTCHA_WIDTH,
        height=settings.CAPTCHA_HEIGHT,
        length=settings.CAPTCHA_LENGTH
    )