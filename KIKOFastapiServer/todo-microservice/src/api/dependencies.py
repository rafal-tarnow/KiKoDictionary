from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from pydantic import BaseModel
from src.core.config import settings

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="http://127.0.0.1:8002/api/v1/auth/login")

class CurrentUser(BaseModel):
    id: str

def get_current_user(token: str = Depends(oauth2_scheme)) -> CurrentUser:
    """Weryfikuje JWT i zwraca obiekt usera."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id = payload.get("sub")
        if user_id is None:
            raise credentials_exception
        return CurrentUser(id=user_id)
    except JWTError:
        raise credentials_exception