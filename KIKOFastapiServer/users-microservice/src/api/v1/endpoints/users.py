from fastapi import APIRouter, Depends
from src.db.models.user import User
from src.api.v1.schemas import user as user_schema
from src.dependencies import get_current_user

router = APIRouter()

@router.get("/me", response_model=user_schema.UserPublic)
async def read_users_me(current_user: User = Depends(get_current_user)):
    """
    Get current logged in user's profile.
    """
    return current_user