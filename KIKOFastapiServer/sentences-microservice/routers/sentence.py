from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from fastapi.responses import JSONResponse
from fastapi.encoders import jsonable_encoder
from schemas.sentence import Sentence, SentenceCreate, SentenceUpdate, PaginatedSentences

# ================= ZMIANA: Importujemy wszystkie funkcje CRUD, w tym nowe =================
from crud.sentence import (
    create_sentence, 
    get_my_sentences, 
    get_community_sentences, 
    get_sentence, 
    update_sentence, 
    delete_sentence,
    clone_sentence
)
from database import get_db

# ================= ZMIANA: Importujemy naszą zależność =================
from dependencies import get_current_user_id, get_optional_user_id
import math

router = APIRouter(prefix="/api/sentences", tags=["sentences"])

# ================= 1. PRZESTRZEŃ PUBLICZNA =================

# ================= [NOWE - PRODUKCJA 8]: Mądry endpoint Community =================
@router.get("/community", response_model=PaginatedSentences) # <--- ZMIANA
def read_community_sentences_endpoint(
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100),
    source_lang: Optional[str] = Query(None, description="Filtruj po języku źródłowym, np. 'en'"),
    target_lang: Optional[str] = Query(None, description="Filtruj po języku docelowym, np. 'pl'"),
    db: Session = Depends(get_db),
    user_id: Optional[str] = Depends(get_optional_user_id) 
):
    sentences, total = get_community_sentences(
        db=db, 
        page=page, 
        per_page=per_page, 
        source_language=source_lang,
        target_language=target_lang
    )
    total_pages = math.ceil(total / per_page) if total > 0 else 1
    
    # [ZMIANA]: FastAPI samo zamieni to na JSON i zwaliduje!
    return {
        "data": sentences,
        "page": page,
        "per_page": per_page,
        "total": total,
        "total_pages": total_pages,
        "is_authenticated": user_id is not None 
    }
    


# ================= [NOWE - PRODUKCJA 9]: Akcja kopiowania =================
# Używamy POST, a status odpowiedzi to 201 Created (standard REST API)
@router.post("/{sentence_id}/clone", response_model=Sentence, status_code=status.HTTP_201_CREATED)
def clone_sentence_endpoint(
    sentence_id: int,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id) # UWAGA: Tutaj autoryzacja jest WYMAGANA
):
    """Kopiuje zdanie ze społeczności i dodaje do prywatnej listy użytkownika."""
    return clone_sentence(db, sentence_id, user_id)
# ==============================================================================


# ================= 2. PRZESTRZEŃ PRYWATNA =================

@router.get("/me", response_model=PaginatedSentences) # <--- ZMIANA
def read_my_sentences_endpoint(
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    sentences, total = get_my_sentences(db, page, per_page, user_id)
    total_pages = math.ceil(total / per_page) if total > 0 else 1
    
    # [ZMIANA]: Czysty słownik, FastAPI ogarnie resztę
    return {
        "data": sentences,
        "page": page,
        "per_page": per_page,
        "total": total,
        "total_pages": total_pages
    }

# CZYSTA KOLEKCJA (DODAWANIE)
@router.post("/", response_model=Sentence)
def create_sentence_endpoint(
    sentence: SentenceCreate, 
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id) # [ZMIANA]: Wymagamy zalogowania
):
    return create_sentence(db, sentence, user_id) # [ZMIANA]: Przekazujemy user_id

# ZABEZPIECZONY KONKRETNY ZASÓB (CZYTANIE/EDYCJA/USUWANIE)
@router.get("/{sentence_id}", response_model=Sentence)
def read_sentence_endpoint(
    sentence_id: int, 
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id) # [ZMIANA]
):
    return get_sentence(db, sentence_id, user_id) # [ZMIANA]

@router.put("/{sentence_id}", response_model=Sentence)
def update_sentence_endpoint(
    sentence_id: int, 
    sentence_update: SentenceUpdate, 
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id) # [ZMIANA]
):
    return update_sentence(db, sentence_id, sentence_update, user_id) # [ZMIANA]

@router.delete("/{sentence_id}")
def delete_sentence_endpoint(
    sentence_id: int, 
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id) # [ZMIANA]
):
    return delete_sentence(db, sentence_id, user_id) # [ZMIANA]