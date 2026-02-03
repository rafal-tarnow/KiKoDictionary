import httpx
from fastapi import APIRouter, Depends, HTTPException, status, Response
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timedelta
from uuid import uuid4

from src.db.session import get_db
from src.db.repository.user_repository import UserRepository
from src.core.security import verify_password, create_access_token, create_refresh_token
from src.api.v1.schemas import user as user_schema
from src.api.v1.schemas.user import UserRegister, UserCreate 
from src.api.v1.schemas import token as token_schema

from src.db.repository.refresh_token_repository import RefreshTokenRepository
from src.core.config import settings
from jose import JWTError, jwt

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication"])


@router.post("/register", response_model=user_schema.UserPublic, status_code=status.HTTP_201_CREATED)
async def register_user(
    user_in: UserRegister, # <--- Używamy schematu zawierającego pola captcha
    db: AsyncSession = Depends(get_db)
):
    # --- 1. WERYFIKACJA CAPTCHA Z TIMEOUTEM ---
    captcha_url = f"{settings.CAPTCHA_SERVICE_URL}/captcha/verify"
    
    captcha_payload = {
        "id": str(user_in.captcha_id),
        "answer": user_in.captcha_answer
    }

    # Ustawienie timeout na 5 sekund
    # timeout=5.0 oznacza: max 5s na nawiązanie połączenia, max 5s na odczyt danych itd.
    async with httpx.AsyncClient(timeout=5.0) as client:
        try:
            response = await client.post(captcha_url, json=captcha_payload)
            response.raise_for_status() # Rzuci błąd jeśli Captcha Service zwróci 4xx lub 5xx
            
            verify_data = response.json()
            
            if not verify_data.get("is_valid"):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST, 
                    detail="Invalid CAPTCHA answer"
                )

        except httpx.TimeoutException:
            # Obsługa przekroczenia czasu oczekiwania (5 sekund)
            print("Błąd: Serwis Captcha nie odpowiedział w ciągu 5 sekund.")
            raise HTTPException(
                status_code=status.HTTP_504_GATEWAY_TIMEOUT, 
                detail="Captcha verification timed out. Please try again later."
            )
            
        except httpx.RequestError as exc:
            # Obsługa braku połączenia (np. serwis leży, zły adres URL)
            print(f"Błąd połączenia z serwisem Captcha: {exc}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE, 
                detail="Captcha service unavailable. Please try again later."
            )
        
        except httpx.HTTPStatusError as exc:
            # Obsługa błędów HTTP (np. 500 z serwera Captcha)
            print(f"Serwis Captcha zwrócił błąd HTTP: {exc.response.status_code}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Error communicating with captcha service."
            )

    # --- 2. LOGIKA BIZNESOWA REJESTRACJI ---
    
    # Konwersja UserRegister -> UserCreate (usuwamy pola captcha)
    user_create_data = UserCreate(
        **user_in.model_dump(exclude={"captcha_id", "captcha_answer"})
    )

    repo = UserRepository(db)
    
    # Sprawdzenie czy email istnieje
    db_user = await repo.get_by_email(email=user_create_data.email)
    if db_user:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")
    
    # Sprawdzenie czy username istnieje
    db_user = await repo.get_by_username(username=user_create_data.username)
    if db_user:
        suggested_username = await repo.suggest_available_username(user_create_data.username)
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, 
            detail={
                "message": "Username already taken",
                "suggestion": suggested_username
            }
        )
    
    # Utworzenie użytkownika
    user = await repo.create(user_data=user_create_data)
    return user


@router.post("/login", response_model=token_schema.Token)
async def login_for_access_token(
    db: AsyncSession = Depends(get_db), 
    form_data: OAuth2PasswordRequestForm = Depends()):

    repo = UserRepository(db)
    user = await repo.get_by_email(email=form_data.username)
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = create_access_token(data={"sub": str(user.id)})
    refresh_token = create_refresh_token(data={"sub": str(user.id)})

    # save RefreshToken
    refresh_token_repo = RefreshTokenRepository(db)
    expires_at = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    await refresh_token_repo.create(
        user_id=user.id,
        token=refresh_token,
        expires_at=expires_at
    )
    
    return {"access_token": access_token, "refresh_token": refresh_token, "token_type": "bearer"}


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    token_request: token_schema.RefreshTokenRequest,
    db: AsyncSession = Depends(get_db)):

    refresh_token_repo = RefreshTokenRepository(db)

    # find token in database
    db_token = await refresh_token_repo.get_by_token(token=token_request.refresh_token)
    
    # if token exist, delete it
    if db_token:
        await refresh_token_repo.delete(token_id=db_token.id)

    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/refresh", response_model=token_schema.Token)
async def refresh_access_token(
    token_request: token_schema.RefreshTokenRequest,
    db: AsyncSession = Depends(get_db)
):
    refresh_token_repo = RefreshTokenRepository(db)
    
    # 1. Znajdź token odświeżający w bazie danych
    db_refresh_token = await refresh_token_repo.get_by_token(token=token_request.refresh_token)

    # 2. Sprawdź, czy token istnieje i czy nie wygasł
    if not db_refresh_token or db_refresh_token.expires_at < datetime.utcnow():
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # 3. Jeśli token istnieje, ALE WYGASŁ, usuń go i odrzuć
    if db_refresh_token.expires_at < datetime.utcnow():
        await refresh_token_repo.delete(token_id=db_refresh_token.id) # <-- DODANA LINIA
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token", # Można zostawić ten sam komunikat
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # 4. Zweryfikuj poprawność samego JWT (chociaż baza jest głównym źródłem prawdy)
    try:
        payload = jwt.decode(
            token_request.refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        if payload.get("type") != "refresh":
             raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Could not validate token")

    # 5. Stwórz nowy token dostępowy
    new_access_token = create_access_token(data={"sub": str(db_refresh_token.user_id)})
    
    # (Token Rotation): unieważnij stary i wydaj nowy refresh token
    await refresh_token_repo.delete(token_id=db_refresh_token.id)
    new_refresh_token = create_refresh_token(data={"sub": str(db_refresh_token.user_id)})
    expires_at = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    await refresh_token_repo.create(
        user_id=db_refresh_token.user_id,
        token=new_refresh_token,
        expires_at=expires_at
    )

    return {
        "access_token": new_access_token,
        "refresh_token": new_refresh_token,
        "token_type": "bearer"
    }