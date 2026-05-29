from sqlalchemy.orm import Session
from sqlalchemy import desc
from models.sentence import Sentence
from schemas.sentence import SentenceCreate, SentenceUpdate
from fastapi import HTTPException, status

from src.core.config import settings
from src.core.exceptions import TierLimitExceededException
from dependencies import CurrentUser



def validate_tier_limits(text: str | None, current_user: CurrentUser, field_name: str):
    """
    Sprawdza, czy przesyłany tekst nie przekracza limitów danego konta.
    Ignoruje puste wartości (None), co pozwala na częściowe update'y.
    """
    if text is None:
        return

    max_allowed = settings.MAX_CHARS_PREMIUM if current_user.is_pro else settings.MAX_CHARS_FREE
    
    if len(text) > max_allowed:
        raise TierLimitExceededException(field=field_name, limit=max_allowed)



def create_sentence(db: Session, sentence: SentenceCreate, current_user: CurrentUser):
    # Walidacja biznesowa
    validate_tier_limits(sentence.original_text, current_user, "original_text")
    validate_tier_limits(sentence.translated_text, current_user, "translated_text")

    db_sentence = Sentence(
        user_id=current_user.id,
        original_text=sentence.original_text,
        translated_text=sentence.translated_text,
        source_language=sentence.source_language,
        target_language=sentence.target_language
    )
    db.add(db_sentence)
    db.commit()
    db.refresh(db_sentence)
    return db_sentence

# [ZMIANA - NOWA NAZWA]: Zwracamy zdania TYLKO danego użytkownika
def get_my_sentences(db: Session, page: int, per_page: int, current_user: CurrentUser):
    """Pobiera zdania tylko zalogowanego użytkownika (Prywatny notatnik)"""
    offset = (page - 1) * per_page
    
    # 2. DODAJEMY SORTOWANIE (ORDER BY created_at DESC)
    # [ZMIANA]: Dodano filtr filter(Sentence.user_id == user_id)
    query = db.query(Sentence).filter(Sentence.user_id == current_user.id).order_by(desc(Sentence.created_at))
    
    # Pobieramy dane z uwzględnieniem paginacji
    sentences = query.offset(offset).limit(per_page).all()
    
    # Liczymy całkowitą ilość (dla paginacji na frontendzie)
    total = query.count() # [ZMIANA]: Zliczamy tylko zdania z query wyżej (dla usera)
    
    return sentences, total

# [ZMIANA]: Pobranie konkretnego zdania Z uwzględnieniem właściciela
def get_sentence(db: Session, sentence_id: int, current_user: CurrentUser):
    sentence = db.query(Sentence).filter(Sentence.id == sentence_id, Sentence.user_id == current_user.id).first()
    if sentence is None:
        raise HTTPException(status_code=404, detail="Sentence not found")
    return sentence


def update_sentence(db: Session, sentence_id: int, sentence_update: SentenceUpdate, current_user: CurrentUser):
    db_sentence = db.query(Sentence).filter(Sentence.id == sentence_id, Sentence.user_id == current_user.id).first()
    if db_sentence is None:
        raise HTTPException(status_code=404, detail="Sentence not found")
    
    # Walidacja biznesowa TYLKO przesyłanych pól. 
    # Jeśli użytkownik Free edytuje np. tylko język, zignorujemy tekst!
    if sentence_update.original_text is not None:
        validate_tier_limits(sentence_update.original_text, current_user, "original_text")
        db_sentence.original_text = sentence_update.original_text
        
    if sentence_update.translated_text is not None:
        validate_tier_limits(sentence_update.translated_text, current_user, "translated_text")
        db_sentence.translated_text = sentence_update.translated_text
        
    if sentence_update.source_language is not None:
        db_sentence.source_language = sentence_update.source_language
        
    if sentence_update.target_language is not None:
        db_sentence.target_language = sentence_update.target_language
    
    db.commit()
    db.refresh(db_sentence)
    return db_sentence

# [ZMIANA]: Usuwanie zdania Z uwzględnieniem właściciela
def delete_sentence(db: Session, sentence_id: int, current_user: CurrentUser):
    db_sentence = db.query(Sentence).filter(Sentence.id == sentence_id, Sentence.user_id == current_user.id).first()
    if db_sentence is None:
        raise HTTPException(status_code=404, detail="Sentence not found")
    db.delete(db_sentence)
    db.commit()
    return {"message": "Sentence deleted successfully"}


# ================= [NOWE - PRODUKCJA 4]: Akcja Klonowania (Mądry Backend) =================
def clone_sentence(db: Session, original_sentence_id: int, current_user: CurrentUser): # <--- ZMIANA: current_user: CurrentUser
    """Kopiuje cudze zdanie ze społeczności i przypisuje je do zalogowanego usera"""
    
    # 1. Pobieramy oryginał
    original = db.query(Sentence).filter(Sentence.id == original_sentence_id).first()
    
    if original is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Original sentence not found")
        
    # 2. Business Logic: Ochrona przed sklonowaniem własnego zdania
    if original.user_id == current_user.id: # <--- ZMIANA
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="You already own this sentence")

    # ================= [NOWA LOGIKA BIZNESOWA: OCHRONA PLANU FREE] =================
    # Musimy sprawdzić, czy użytkownik FREE nie próbuje sklonować zdania usera PRO, 
    # które przekracza darmowy limit!
    validate_tier_limits(original.original_text, current_user, "original_text")
    validate_tier_limits(original.translated_text, current_user, "translated_text")
    # ===============================================================================

    # 3. Zabezpieczenie przed podwójnym klonowaniem
    already_saved = db.query(Sentence).filter(
        Sentence.user_id == current_user.id, # <--- ZMIANA
        Sentence.original_text == original.original_text,
        Sentence.translated_text == original.translated_text,
        Sentence.source_language == original.source_language,
        Sentence.target_language == original.target_language
    ).first()

    if already_saved:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="You have already saved this sentence to your list."
        )

    # 4. Klonowanie
    cloned_sentence = Sentence(
        user_id=current_user.id, # <--- ZMIANA
        original_text=original.original_text,
        translated_text=original.translated_text,
        source_language=original.source_language,
        target_language=original.target_language
    )
    
    db.add(cloned_sentence)
    db.commit()
    db.refresh(cloned_sentence)
    return cloned_sentence

# ================= 2. PRZESTRZEŃ PUBLICZNA (Społeczność) =================

# ================= [NOWE - PRODUKCJA 5]: Filtrowanie po językach =================
def get_community_sentences(
    db: Session, 
    page: int, 
    per_page: int, 
    source_language: str = None, 
    target_language: str = None
):
    offset = (page - 1) * per_page
    query = db.query(Sentence)
    
    # Aplikujemy filtry tylko wtedy, gdy frontend je przesłał
    if source_language:
        query = query.filter(Sentence.source_language == source_language)
    if target_language:
        query = query.filter(Sentence.target_language == target_language)
        
    query = query.order_by(desc(Sentence.created_at))
    sentences = query.offset(offset).limit(per_page).all()
    total = query.count()
    
    return sentences, total
# =================================================================================