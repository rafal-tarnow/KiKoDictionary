
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.config import settings
from src.db.models.user import User as UserDb
from src.db.repository.user_repository import UserRepository
from src.db.session import get_db
from src.api.v1.schemas.token import TokenData

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

async def get_current_user(
        db: AsyncSession = Depends(get_db), token: str = Depends(oauth2_scheme)
) -> UserDb:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        token_type: str = payload.get("type")
        
        if user_id is None or token_type != "access":
            raise credentials_exception
        token_data = TokenData(user_id=user_id)
    except JWTError:
        raise credentials_exception
    
    repo = UserRepository(db)
    user = await repo.get_by_id(user_id=token_data.user_id)
    
    # [ZMIANA]: Sprawdzamy czy user istnieje ORAZ czy nie ma zbanowanego/usuniętego konta
    if user is None or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is deactivated or deleted"
        )
        
    return user
    

    