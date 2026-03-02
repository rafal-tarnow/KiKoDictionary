from fastapi import APIRouter, Depends, status, Response
from sqlalchemy.ext.asyncio import AsyncSession

from src.db.session import get_db
from src.db.models.user import User as UserDb
from src.dependencies import get_current_user
from src.db.repository.user_repository import UserRepository
from src.db.repository.refresh_token_repository import RefreshTokenRepository
from src.db.repository.user_profile_repository import UserProfileRepository
from src.api.v1.schemas import user as user_schema
from src.api.v1.schemas.user_profile import UserProfileUpdate, UserProfilePublic

# Tworzymy oddzielny router do zarządzania profilami użytkowników
router = APIRouter(prefix="/api/v1/users", tags=["Users"])

@router.get("/me", response_model=user_schema.UserPublic)
async def read_users_me(
    current_user: UserDb = Depends(get_current_user),
    db: AsyncSession = Depends(get_db) # <--- DODAJ TĘ LINIJKĘ
):
    """
    Pobiera dane aktualnie zalogowanego użytkownika WRAZ Z PROFILEM.
    Zwracany JSON będzie zawierał obiekt "profile": {"native_language": "en", ...}
    """
    # --- [ZMIANA]: AUTO-HEALING DLA STARYCH KONT ---
    if current_user.profile is None:
        profile_repo = UserProfileRepository(db)
        
        # Wykorzystujemy naszą genialną metodę update_profile, która ma wbudowany
        # mechanizm (fallback) tworzenia profilu, jeśli ten nie istnieje w bazie.
        # Przekazujemy puste ustawienia, więc zaaplikują się domyślne (np. "en").
        current_user.profile = await profile_repo.update_profile(
            user_id=current_user.id, 
            profile_data=UserProfileUpdate() 
        )
    # ----------------------------------------------
    return current_user

# --- [ZMIANA]: NOWY ENDPOINT DO AKTUALIZACJI JĘZYKA / USTAWIEŃ ---
@router.patch("/me/profile", response_model=UserProfilePublic)
async def update_user_profile(
    profile_update: UserProfileUpdate,
    current_user: UserDb = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Aktualizuje preferencje użytkownika (np. zmiana języka aplikacji).
    Frontend wysyła np. {"native_language": "es"}
    """
    profile_repo = UserProfileRepository(db)
    updated_profile = await profile_repo.update_profile(
        user_id=current_user.id, 
        profile_data=profile_update
    )
    return updated_profile
# ----------------------------------------------------------------


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user_me(
    current_user: UserDb = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Trwale usuwa konto aktualnie zalogowanego użytkownika.
    Operacja wykorzystuje bezpieczne 'Soft Delete' z anonimizacją danych.
    """
    user_repo = UserRepository(db)
    refresh_token_repo = RefreshTokenRepository(db)
    
    # 1. Wyloguj użytkownika ze wszystkich urządzeń (usuń Refresh Tokeny)
    await refresh_token_repo.delete_all_for_user(current_user.id)
    
    # 2. Zastosuj anonimizację i Soft Delete na koncie
    await user_repo.soft_delete_user(current_user)
    
    # Zwracamy 204 No Content (Standard HTTP przy udanym usunięciu zasobu)
    return Response(status_code=status.HTTP_204_NO_CONTENT)