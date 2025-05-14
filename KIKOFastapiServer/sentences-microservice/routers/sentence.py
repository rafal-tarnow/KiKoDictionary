from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from typing import List
from fastapi.responses import JSONResponse
from fastapi.encoders import jsonable_encoder  # Dodaj ten import
from schemas.sentence import Sentence, SentenceCreate, SentenceUpdate
from crud.sentence import create_sentence, get_sentences, get_sentence, update_sentence, delete_sentence
from database import get_db
import math

router = APIRouter(prefix="/api/sentences", tags=["sentences"])

@router.post("/", response_model=Sentence)
def create_sentence_endpoint(sentence: SentenceCreate, db: Session = Depends(get_db)):
    return create_sentence(db, sentence)

@router.get("/", response_model=List[Sentence])
def read_sentences_endpoint(
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db)
):
    sentences, total = get_sentences(db, page, per_page)
    total_pages = math.ceil(total / per_page)
    
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

@router.get("/{sentence_id}", response_model=Sentence)
def read_sentence_endpoint(sentence_id: int, db: Session = Depends(get_db)):
    return get_sentence(db, sentence_id)

@router.put("/{sentence_id}", response_model=Sentence)
def update_sentence_endpoint(sentence_id: int, sentence_update: SentenceUpdate, db: Session = Depends(get_db)):
    return update_sentence(db, sentence_id, sentence_update)

@router.delete("/{sentence_id}")
def delete_sentence_endpoint(sentence_id: int, db: Session = Depends(get_db)):
    return delete_sentence(db, sentence_id)