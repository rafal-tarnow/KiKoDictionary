from sqlalchemy.orm import Session
from models.sentence import Sentence
from schemas.sentence import SentenceCreate, SentenceUpdate
from fastapi import HTTPException

def create_sentence(db: Session, sentence: SentenceCreate):
    db_sentence = Sentence(
        sentence=sentence.sentence,
        language=sentence.language,
        translation=sentence.translation
    )
    db.add(db_sentence)
    db.commit()
    db.refresh(db_sentence)
    return db_sentence

def get_sentences(db: Session, page: int, per_page: int):
    offset = (page - 1) * per_page
    return db.query(Sentence).offset(offset).limit(per_page).all(), db.query(Sentence).count()

def get_sentence(db: Session, sentence_id: int):
    sentence = db.query(Sentence).filter(Sentence.id == sentence_id).first()
    if sentence is None:
        raise HTTPException(status_code=404, detail="Sentence not found")
    return sentence

def update_sentence(db: Session, sentence_id: int, sentence_update: SentenceUpdate):
    db_sentence = db.query(Sentence).filter(Sentence.id == sentence_id).first()
    if db_sentence is None:
        raise HTTPException(status_code=404, detail="Sentence not found")
    
    if sentence_update.sentence is not None:
        db_sentence.sentence = sentence_update.sentence
    if sentence_update.language is not None:
        db_sentence.language = sentence_update.language
    if sentence_update.translation is not None:
        db_sentence.translation = sentence_update.translation
    
    db.commit()
    db.refresh(db_sentence)
    return db_sentence

def delete_sentence(db: Session, sentence_id: int):
    db_sentence = db.query(Sentence).filter(Sentence.id == sentence_id).first()
    if db_sentence is None:
        raise HTTPException(status_code=404, detail="Sentence not found")
    db.delete(db_sentence)
    db.commit()
    return {"message": "Sentence deleted successfully"}