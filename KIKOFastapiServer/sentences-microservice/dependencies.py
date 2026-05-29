from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from typing import Optional
from pydantic import BaseModel

from src.core.config import settings

# OAuth2PasswordBearer "tłumaczy" FastAPI, że aplikacja oczekuje nagłówka Authorization: Bearer <token>
# tokenUrl nie ma tu znaczenia dla walidacji, służy tylko dokumentacji Swagger UI
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="http://127.0.0.1:8002/api/v1/auth/login")


# ================= [NOWE - PRODUKCJA 1]: Opcjonalna Autoryzacja =================
# auto_error=False sprawia, że brak tokena nie rzuca od razu błędu 401.
oauth2_scheme_optional = OAuth2PasswordBearer(
    tokenUrl="http://127.0.0.1:8002/api/v1/auth/login", 
    auto_error=False
)


def get_optional_user_id(token: Optional[str] = Depends(oauth2_scheme_optional)) -> Optional[str]:
    """
    Sprawdza token, jeśli istnieje. Używane dla endpointów publicznych (np. Community),
    które chcą wiedzieć CZY ktoś jest zalogowany, ale nie WYMUSZAJĄ tego.
    Zwraca user_id (str) lub None.
    """
    if not token:
        return None
        
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: Optional[str] = payload.get("sub")
        token_type: Optional[str] = payload.get("type")
        
        if user_id is None or token_type != "access":
            return None
            
        return user_id
    except JWTError:
        return None
# ===================================================================================

class CurrentUser(BaseModel):
    id: str
    tier: str = "free" # Zabezpieczenie: domyślnie free
    
    @property
    def is_pro(self) -> bool:
        return self.tier.lower() == "pro"


def get_current_user(token: str = Depends(oauth2_scheme)) -> CurrentUser:
    """
    Weryfikuje token JWT i wyciąga z niego 'sub' (czyli user_id).
    Rzuca 401 Unauthorized, jeśli token jest nieważny, wygasły lub sfałszowany.
    Zwraca string (UUID) reprezentujący ID użytkownika.
    Weryfikuje token i wyciąga obiekt usera z jego tierem (pro/free).
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        
        user_id: Optional[str] = payload.get("sub")
        token_type: Optional[str] = payload.get("type")
        tier: str = payload.get("tier", "free") # <--- Wyciągamy tier (musisz to dodać w serwisie logowania)
        
        if user_id is None or token_type != "access":
            raise credentials_exception
            
        return CurrentUser(id=user_id, tier=tier)
    except JWTError:
        raise credentials_exception