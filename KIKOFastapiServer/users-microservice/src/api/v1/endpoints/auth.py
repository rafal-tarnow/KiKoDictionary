from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession

from src.db.session import get_db
from src.db.repository.user_repository import UserRepository
from src.core.security import create_access_token, create_refresh_token, verify_password
from src.api.v1.schemas import user as user_schema
from src.api.v1.schemas import token as token_schema
from src.services.captcha_service import CaptchaService

router = APIRouter()

@router.post("/register", response_model=user_schema.UserPublic, status_code=status.HTTP_201_CREATED)
async def register_user(
    user_in: user_schema.UserCreate, 
    db: AsyncSession = Depends(get_db)
):
    # 1. Verify CAPTCHA
    captcha_service = CaptchaService()
    is_valid = await captcha_service.verify(user_in.captcha_id, user_in.captcha_answer)
    if not is_valid:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid CAPTCHA")

    # 2. Check if user already exists
    repo = UserRepository(db)
    db_user = await repo.get_by_email(email=user_in.email)
    if db_user:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")
    
    db_user = await repo.get_by_username(username=user_in.username)
    if db_user:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Username already taken")

    # 3. Create user
    user = await repo.create(user_data=user_in)
    return user

@router.post("/login", response_model=token_schema.Token)
async def login_for_access_token(
    db: AsyncSession = Depends(get_db), 
    form_data: OAuth2PasswordRequestForm = Depends()
):
    # Note: In a real app, form_data would be extended to include captcha fields.
    # For simplicity, we'll assume the frontend sends captcha data separately or we add it to the form.
    # We will simulate CAPTCHA check here. In a real frontend, you'd get this from the form.
    # captcha_id = form_data.get("captcha_id")
    # captcha_answer = form_data.get("captcha_answer")
    # if not captcha_id or not captcha_answer:
    #     raise HTTPException(status_code=400, detail="CAPTCHA required for login")
    # captcha_service = CaptchaService()
    # if not await captcha_service.verify(captcha_id, captcha_answer):
    #     raise HTTPException(status_code=400, detail="Invalid CAPTCHA")

    repo = UserRepository(db)
    user = await repo.get_by_username(username=form_data.username)
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = create_access_token(data={"sub": str(user.id)})
    refresh_token = create_refresh_token(data={"sub": str(user.id)})
    
    return {"access_token": access_token, "refresh_token": refresh_token, "token_type": "bearer"}