from sqlalchemy.orm import Session
from sqlalchemy import desc
from models.sentence import Sentence
from schemas.sentence import SentenceCreate, SentenceUpdate
from fastapi import HTTPException

# ================= 1. PRZESTRZEŃ PRYWATNA (Wymaga user_id) =================

# [ZMIANA]: Wymagamy user_id przy tworzeniu
def create_sentence(db: Session, sentence: SentenceCreate, user_id: str):
    # ================= [ZMIANA 3]: Mapowanie nowych pól przy tworzeniu =================
    db_sentence = Sentence(
        user_id=user_id,
        original_text=sentence.original_text,
        translated_text=sentence.translated_text,
        source_language=sentence.source_language,
        target_language=sentence.target_language
    )
    # ===================================================================================
    db.add(db_sentence)
    db.commit()
    db.refresh(db_sentence)
    return db_sentence

# [ZMIANA - NOWA NAZWA]: Zwracamy zdania TYLKO danego użytkownika
def get_my_sentences(db: Session, page: int, per_page: int, user_id: str):
    """Pobiera zdania tylko zalogowanego użytkownika (Prywatny notatnik)"""
    offset = (page - 1) * per_page
    
    # 2. DODAJEMY SORTOWANIE (ORDER BY created_at DESC)
    # [ZMIANA]: Dodano filtr filter(Sentence.user_id == user_id)
    query = db.query(Sentence).filter(Sentence.user_id == user_id).order_by(desc(Sentence.created_at))
    
    # Pobieramy dane z uwzględnieniem paginacji
    sentences = query.offset(offset).limit(per_page).all()
    
    # Liczymy całkowitą ilość (dla paginacji na frontendzie)
    total = query.count() # [ZMIANA]: Zliczamy tylko zdania z query wyżej (dla usera)
    
    return sentences, total

# [ZMIANA]: Pobranie konkretnego zdania Z uwzględnieniem właściciela
def get_sentence(db: Session, sentence_id: int, user_id: str):
    sentence = db.query(Sentence).filter(Sentence.id == sentence_id, Sentence.user_id == user_id).first()
    if sentence is None:
        raise HTTPException(status_code=404, detail="Sentence not found")
    return sentence

# [ZMIANA]: Aktualizacja zdania Z uwzględnieniem właściciela
def update_sentence(db: Session, sentence_id: int, sentence_update: SentenceUpdate, user_id: str):
    db_sentence = db.query(Sentence).filter(Sentence.id == sentence_id, Sentence.user_id == user_id).first()
    if db_sentence is None:
        raise HTTPException(status_code=404, detail="Sentence not found")
    
    # ================= [ZMIANA 4]: Mapowanie nowych pól przy aktualizacji =================
    if sentence_update.original_text is not None:
        db_sentence.original_text = sentence_update.original_text
    if sentence_update.translated_text is not None:
        db_sentence.translated_text = sentence_update.translated_text
    if sentence_update.source_language is not None:
        db_sentence.source_language = sentence_update.source_language
    if sentence_update.target_language is not None:
        db_sentence.target_language = sentence_update.target_language
    # ======================================================================================
    
    db.commit()
    db.refresh(db_sentence)
    return db_sentence

# [ZMIANA]: Usuwanie zdania Z uwzględnieniem właściciela
def delete_sentence(db: Session, sentence_id: int, user_id: str):
    db_sentence = db.query(Sentence).filter(Sentence.id == sentence_id, Sentence.user_id == user_id).first()
    if db_sentence is None:
        raise HTTPException(status_code=404, detail="Sentence not found")
    db.delete(db_sentence)
    db.commit()
    return {"message": "Sentence deleted successfully"}


# ================= 2. PRZESTRZEŃ PUBLICZNA (Społeczność) =================

# [ZMIANA]: CAŁKIEM NOWA FUNKCJA pobierająca wszystko od wszystkich
def get_community_sentences(db: Session, page: int, per_page: int):
    """Pobiera wszystkie zdania w systemie (Feed Społecznościowy) bez względu na to czyje są."""
    offset = (page - 1) * per_page
    
    # Sortujemy najnowsze na górze (brak filtra na user_id!)
    query = db.query(Sentence).order_by(desc(Sentence.created_at))
    sentences = query.offset(offset).limit(per_page).all()
    total = query.count()
    
    return sentences, total