from dataclasses import dataclass

from jose import JWTError, jwt

from src.core.config import settings
from src.core.exceptions import AuthenticationError

ACCESS_TOKEN_TYPE = "access"


@dataclass(frozen=True, slots=True)
class CurrentUser:
    """Uzytkownik wyciagniety z tokena JWT wystawionego przez auth-microservice."""

    id: str


def decode_access_token(token: str) -> CurrentUser:
    """
    Weryfikuje podpis i waznosc tokena. Serwis nie ma wlasnej tabeli userow -
    ufa tokenom podpisanym wspolnym SECRET_KEY (tak jak todo i sentences).
    """
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    except JWTError as exc:
        raise AuthenticationError() from exc

    user_id = payload.get("sub")
    # Odrzucamy refresh tokeny - do API wpuszczamy tylko access token
    if not user_id or payload.get("type") != ACCESS_TOKEN_TYPE:
        raise AuthenticationError()

    return CurrentUser(id=str(user_id))
