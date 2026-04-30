from sqlalchemy.orm import Session
from sqlalchemy import desc
from models.sentence import Sentence
from schemas.sentence import SentenceCreate, SentenceUpdate
from fastapi import HTTPException, status

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


# ================= [NOWE - PRODUKCJA 4]: Akcja Klonowania (Mądry Backend) =================
def clone_sentence(db: Session, original_sentence_id: int, new_user_id: str):
    """Kopiuje cudze zdanie ze społeczności i przypisuje je do zalogowanego usera"""
    
    # 1. Pobieramy oryginał (bez względu na to kto jest właścicielem)
    original = db.query(Sentence).filter(Sentence.id == original_sentence_id).first()
    
    if original is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Original sentence not found")
        
    # 2. Business Logic: Ochrona przed sklonowaniem własnego zdania
    if original.user_id == new_user_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="You already own this sentence")

    # ================= [NOWE - Zabezpieczenie przed Spamem/Podwójnym klonowaniem] =================
    # 3. Business Logic: Sprawdzamy, czy użytkownik już wcześniej nie sklonował tego zdania
    already_saved = db.query(Sentence).filter(
        Sentence.user_id == new_user_id,
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
    # ==============================================================================================

    # 4. Klonowanie: Tworzymy nowy obiekt przypisany do usera, NIE KOPIUJEMY starego 'id' ani 'created_at'
    cloned_sentence = Sentence(
        user_id=new_user_id,
        original_text=original.original_text,
        translated_text=original.translated_text,
        source_language=original.source_language,
        target_language=original.target_language
    )
    
    db.add(cloned_sentence)
    db.commit()
    db.refresh(cloned_sentence)
    return cloned_sentence
# =========================================================================================

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