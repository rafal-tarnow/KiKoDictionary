from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import uuid4

from src.db.session import get_db
from src.db.repository.user_repository import UserRepository
from src.api.v1.schemas import user as user_schema 

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication"])

@router.post("/register", response_model=user_schema.UserPublic, status_code=status.HTTP_201_CREATED)
async def register_user(user_in: user_schema.UserCreate,
                        db: AsyncSession = Depends(get_db)):
    # Check if user already exist
    repo = UserRepository(db)
    db_user = await repo.get_by_email(email=user_in.email)
    if db_user:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")
    
    # Create user
    user = await repo.create(user_data=user_in)
    return user