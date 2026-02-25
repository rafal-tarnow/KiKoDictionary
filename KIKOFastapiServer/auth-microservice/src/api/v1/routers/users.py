from fastapi import APIRouter, Depends, status, Response
from sqlalchemy.ext.asyncio import AsyncSession

from src.db.session import get_db
from src.db.models.user import User as UserDb
from src.dependencies import get_current_user
from src.db.repository.user_repository import UserRepository
from src.db.repository.refresh_token_repository import RefreshTokenRepository
from src.api.v1.schemas import user as user_schema

# Tworzymy oddzielny router do zarządzania profilami użytkowników
router = APIRouter(prefix="/api/v1/users", tags=["Users"])

@router.get("/me", response_model=user_schema.UserPublic)
async def read_users_me(current_user: UserDb = Depends(get_current_user)):
    """
    Pobiera dane aktualnie zalogowanego użytkownika.
    """
    return current_user

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