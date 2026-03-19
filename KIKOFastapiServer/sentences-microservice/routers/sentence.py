from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from typing import List
from fastapi.responses import JSONResponse
from fastapi.encoders import jsonable_encoder
from schemas.sentence import Sentence, SentenceCreate, SentenceUpdate

# ================= ZMIANA: Importujemy wszystkie funkcje CRUD, w tym nowe =================
from crud.sentence import (
    create_sentence, 
    get_my_sentences, 
    get_community_sentences, 
    get_sentence, 
    update_sentence, 
    delete_sentence
)
from database import get_db

# ================= ZMIANA: Importujemy naszą zależność =================
from dependencies import get_current_user_id
import math

router = APIRouter(prefix="/api/sentences", tags=["sentences"])

# ================= 1. PRZESTRZEŃ PUBLICZNA =================

# [ZMIANA]: Nowy, otwarty endpoint. 
# Zwróć uwagę na brak "user_id = Depends(...)". To pozwala przeglądać gościom.
@router.get("/community", response_model=List[Sentence])
def read_community_sentences_endpoint(
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db)
):
    sentences, total = get_community_sentences(db, page, per_page)
    total_pages = math.ceil(total / per_page) if total > 0 else 1
    
    items = [Sentence.from_orm(s) for s in sentences]
    encoded_items = jsonable_encoder(items)
    
    return JSONResponse(
        content={
            "data": encoded_items,
            "page": page,
            "per_page": per_page,
            "total": total,
            "total_pages": total_pages
        }
    )

# ================= 2. PRZESTRZEŃ PRYWATNA =================

# [ZMIANA]: Przepinamy pobieranie prywatnej listy na ścieżkę /me
@router.get("/me", response_model=List[Sentence])
def read_my_sentences_endpoint(
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id) # [ZMIANA]: Wymagamy zalogowania
):
    sentences, total = get_my_sentences(db, page, per_page, user_id) # [ZMIANA]: Nowa funkcja
    total_pages = math.ceil(total / per_page) if total > 0 else 1
    
    # Użyj jsonable_encoder do konwersji listy obiektów Sentence
    items = [Sentence.from_orm(s) for s in sentences]
    encoded_items = jsonable_encoder(items)
    
    return JSONResponse(
        content={
            "data": encoded_items,
            "page": page,
            "per_page": per_page,
            "total": total,
            "total_pages": total_pages
        }
    )

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