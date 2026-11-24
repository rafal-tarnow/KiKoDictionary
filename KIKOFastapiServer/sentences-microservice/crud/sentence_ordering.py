"""
Ręczna kolejność zdań na liście "My Sentences".

Każde zdanie ma `position: float` (mniejsza = wyżej). Przeniesienie zmienia tylko pozycję
przesuwanego zdania (średnia z sąsiadów), więc jedna operacja = jeden UPDATE.
Kolejność liczy się osobno dla każdego użytkownika.

- nowe zdanie       -> na sam początek listy (mniejsza pozycja niż wszystkie)
- "na początek"     -> jak wyżej
- "na koniec"       -> większa pozycja niż wszystkie
- przeciągnięcie    -> pomiędzy dwóch sąsiadów (prev_id / next_id)

Gdy po wielu przesunięciach w to samo miejsce przerwa między sąsiadami spadnie poniżej
precyzji float, lista użytkownika jest jednorazowo przenumerowana.
"""

from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from models.sentence import Sentence

POSITION_STEP = 1000.0
POSITION_MIN_GAP = 1e-6


def position_between(lower: float | None, upper: float | None) -> float:
    """Pozycja pomiędzy `lower` a `upper` (None = brak sąsiada z tej strony)."""
    if lower is not None and upper is not None:
        return (lower + upper) / 2.0
    if lower is not None:
        return lower + POSITION_STEP
    if upper is not None:
        return upper - POSITION_STEP
    return POSITION_STEP


def _user_query(db: Session, user_id: str):
    return db.query(Sentence).filter(Sentence.user_id == user_id)


def position_for_new_sentence(db: Session, user_id: str) -> float:
    """Nowe zdanie trafia na sam początek listy użytkownika."""
    min_position = db.query(func.min(Sentence.position)).filter(Sentence.user_id == user_id).scalar()
    return position_between(None, min_position)


def move_to_top(db: Session, sentence: Sentence) -> None:
    min_other = (
        db.query(func.min(Sentence.position))
        .filter(Sentence.user_id == sentence.user_id, Sentence.id != sentence.id)
        .scalar()
    )
    if min_other is None or sentence.position < min_other:
        return  # Już jest na górze (albo jedyne zdanie)
    sentence.position = position_between(None, min_other)


def move_to_bottom(db: Session, sentence: Sentence) -> None:
    max_other = (
        db.query(func.max(Sentence.position))
        .filter(Sentence.user_id == sentence.user_id, Sentence.id != sentence.id)
        .scalar()
    )
    if max_other is None or sentence.position > max_other:
        return  # Już jest na dole (albo jedyne zdanie)
    sentence.position = position_between(max_other, None)


def move_between(db: Session, sentence: Sentence, prev_id: int | None, next_id: int | None) -> None:
    """
    Ustawia zdanie między `prev_id` (nad nim) a `next_id` (pod nim).

    Kotwicą jest `prev_id` (a gdy go brak - `next_id`); drugiego sąsiada dobieramy z bazy.
    Dzięki temu wynik jest poprawny także na granicy stron (klient widzi tylko jedną stronę)
    i przy lekko nieaktualnej liście po stronie klienta.
    """
    if sentence.id in (prev_id, next_id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Sentence cannot be its own neighbour")
    if prev_id is None and next_id is None:
        return

    prev_sentence = _get_neighbour(db, sentence.user_id, prev_id)
    next_sentence = _get_neighbour(db, sentence.user_id, next_id)

    lower, upper = _resolve_bounds(db, sentence, prev_sentence, next_sentence)
    if lower is not None and upper is not None and upper - lower < POSITION_MIN_GAP:
        _renumber(db, sentence.user_id)
        lower, upper = _resolve_bounds(db, sentence, prev_sentence, next_sentence)

    sentence.position = position_between(lower, upper)


def _get_neighbour(db: Session, user_id: str, sentence_id: int | None) -> Sentence | None:
    if sentence_id is None:
        return None
    neighbour = _user_query(db, user_id).filter(Sentence.id == sentence_id).first()
    if neighbour is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=f"Neighbour sentence {sentence_id} not found"
        )
    return neighbour


def _resolve_bounds(
    db: Session, sentence: Sentence, prev_sentence: Sentence | None, next_sentence: Sentence | None
) -> tuple[float | None, float | None]:
    others = _user_query(db, sentence.user_id).filter(Sentence.id != sentence.id)
    if prev_sentence is not None:
        after = (
            others.filter(Sentence.position > prev_sentence.position)
            .order_by(Sentence.position.asc(), Sentence.id.asc())
            .first()
        )
        return prev_sentence.position, after.position if after else None

    assert next_sentence is not None
    before = (
        others.filter(Sentence.position < next_sentence.position)
        .order_by(Sentence.position.desc(), Sentence.id.desc())
        .first()
    )
    return before.position if before else None, next_sentence.position


def _renumber(db: Session, user_id: str) -> None:
    """Równe odstępy (1000, 2000, ...) z zachowaniem obecnej kolejności."""
    ordered = _user_query(db, user_id).order_by(Sentence.position.asc(), Sentence.id.asc()).all()
    for index, item in enumerate(ordered, start=1):
        item.position = index * POSITION_STEP
    db.flush()
