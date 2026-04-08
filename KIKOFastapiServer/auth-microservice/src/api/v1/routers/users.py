from fastapi import APIRouter, Depends, status, Response, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from src.db.session import get_db
from src.db.models.user import User as UserDb
from src.dependencies import get_current_user
from src.db.repository.user_repository import UserRepository
from src.db.repository.refresh_token_repository import RefreshTokenRepository
from src.db.repository.user_profile_repository import UserProfileRepository
from src.api.v1.schemas import user as user_schema
from src.api.v1.schemas.user_profile import UserProfileUpdate, UserProfilePublic
from src.api.v1.schemas.user import UserUpdateUsername

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


@router.patch("/me/username", response_model=user_schema.UserPublic)
async def update_username(
    username_update: UserUpdateUsername,
    current_user: UserDb = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Zmienia nazwę użytkownika (Core Identity).
    Pozwala na zmianę wielkości liter własnego loginu (np. z 'Ania' na 'ania').
    Jeśli nazwa jest zajęta przez INNEGO użytkownika, zwraca kod 409 i sugeruje wolne alternatywy.
    """
    new_username = username_update.username
    
    # ================= [ZMIANA 1]: Blokujemy tylko IDENTYCZNE ciągi znaków =================
    # Jeśli wysłał dokładnie "Ania", a w bazie ma "Ania" - oszczędzamy bazę i zwracamy sukces.
    # Usunęliśmy tu użycie .lower(), aby "Ania" != "ania" przeszło dalej!
    if current_user.username == new_username:
        return current_user
    # =========================================================================================
        
    user_repo = UserRepository(db)
    
    # 2. Sprawdzenie, czy nowa nazwa jest wolna
    existing_user = await user_repo.get_by_username(new_username)
    
    # ================= [ZMIANA 2]: Inteligentna obsługa Konfliktu (Casing Exception) =================
    # Błąd 409 rzucamy TYLKO wtedy, gdy ktoś inny ma już tę nazwę.
    # Jeśli existing_user to my sami (existing_user.id == current_user.id), 
    # to znaczy, że po prostu zmieniamy "Ania" na "ania" lub "ANIA" i pozwalamy na to.
    if existing_user and existing_user.id != current_user.id:
        # POBIERAMY SUGESTIE (Magia UX!)
        suggestions = await user_repo.suggest_available_usernames(new_username)
        
        # Zwracamy złożony obiekt JSON z błędem i pomocną dłonią dla frontendu
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "message": "Username already taken",
                "suggestions": suggestions
            }
        )
    # =================================================================================================
        
    # 3. Jeśli wolne (lub zmieniamy tylko własny Casing) - zmieniamy, zapisujemy i zwracamy zaktualizowany obiekt
    current_user.username = new_username
    updated_user = await user_repo.update(current_user)
    
    return updated_user
    

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