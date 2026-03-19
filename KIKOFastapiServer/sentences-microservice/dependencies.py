from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from typing import Optional

from src.core.config import settings

# OAuth2PasswordBearer "tłumaczy" FastAPI, że aplikacja oczekuje nagłówka Authorization: Bearer <token>
# tokenUrl nie ma tu znaczenia dla walidacji, służy tylko dokumentacji Swagger UI
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="http://127.0.0.1:8002/api/v1/auth/login")

def get_current_user_id(token: str = Depends(oauth2_scheme)) -> str:
    """
    Weryfikuje token JWT i wyciąga z niego 'sub' (czyli user_id).
    Rzuca 401 Unauthorized, jeśli token jest nieważny, wygasły lub sfałszowany.
    Zwraca string (UUID) reprezentujący ID użytkownika.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        # Dekodowanie z użyciem SECRET_KEY z serwisu Auth
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        
        # Wyciągnięcie ID usera i upewnienie się, że to token dostępowy, a nie odświeżający
        user_id: Optional[str] = payload.get("sub")
        token_type: Optional[str] = payload.get("type")
        
        if user_id is None or token_type != "access":
            raise credentials_exception
            
        return user_id
    except JWTError:
        raise credentials_exception