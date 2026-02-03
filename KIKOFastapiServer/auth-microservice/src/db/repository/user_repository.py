from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import or_, func
from src.db.models.user import User
from src.api.v1.schemas.user import UserCreate
from src.core.security import get_password_hash
import re

class UserRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def get_by_email(self, email: str) -> Optional[User]:
        # Email jest zawsze lowercase (wymuszone w schemas), ale dla bezpieczeństwa:
        email_lower = email.lower()
        result = await self.db.execute(select(User).filter(User.email == email_lower))
        return result.scalars().first()
    

    async def get_by_username(self, username: str) -> Optional[User]:
        """
        Wyszukuje użytkownika ignorując wielkość liter.
        Dla wejścia 'tom' znajdzie użytkownika 'Tom'.
        """
        username_lower = username.lower()
        # Porównujemy lower(db_column) == lower(input)
        result = await self.db.execute(
            select(User).filter(func.lower(User.username) == username_lower)
        )
        return result.scalars().first()
    
    async def get_by_id(self, user_id: str) -> Optional[User]:
        result = await self.db.execute(select(User).filter(User.id == user_id))
        return result.scalars().first()
    

    async def get_by_email_or_username(self, identifier: str) -> Optional[User]:
        """
        Logowanie: Sprawdza czy identyfikator pasuje do emaila lub username
        (w obu przypadkach case-insensitive).
        """
        identifier_lower = identifier.lower()

        # Szukamy po emailu LUB po username (ignorując wielkość liter w obu przypadkach)
        result = await self.db.execute(
            select(User).filter(
                or_(
                    User.email == identifier_lower,
                    func.lower(User.username) == identifier_lower
                )
            )
        )
        return result.scalars().first()
    

    async def create(self, user_data: UserCreate) -> User:
        hashed_password = get_password_hash(user_data.password)
        
        # WAŻNE: Zapisujemy user_data.username W ORYGINALE (np. "RafalDev").
        # Unikalność ("rafaldev" vs "RafalDev") jest pilnowana przez:
        # 1. get_by_username() użyte w routerze przed zapisem (Application Layer check)
        # 2. Index unique na func.lower(username) w bazie (Database Layer check)
        
        db_user = User(
            username=user_data.username, # Zachowujemy casing dla ładnego wyświetlania
            email=user_data.email.lower(),
            hashed_password=hashed_password,
        )
        self.db.add(db_user)
        await self.db.commit()
        await self.db.refresh(db_user)
        return db_user
    

    async def suggest_available_username(self, username: str) -> str:
        """
        Generuje unikalną nazwę użytkownika, dodając liczbę na końcu.
        Np. jeśli 'Tom' jest zajęty, szuka 'Tom1', 'Tom2'... i zwraca pierwszy wolny.
        """
        base_username = username
        
        # Pobieramy wszystkie loginy, które zaczynają się tak samo (ignorując wielkość liter)
        # Używamy LIKE 'username%', żeby znaleźć 'Tom', 'Tom1', 'Tom999'
        query = select(User.username).filter(
            func.lower(User.username).like(f"{base_username.lower()}%")
        )
        result = await self.db.execute(query)
        existing_usernames = result.scalars().all()

        # Jeśli nie ma żadnych konfliktów (teoretycznie funkcja wywoływana tylko gdy są), zwracamy oryginał
        if not existing_usernames:
            return base_username

        # Tworzymy zbiór małych liter dla szybkiego sprawdzania
        existing_set = {u.lower() for u in existing_usernames}

        # Jeśli podstawowa nazwa jest wolna (np. ktoś usunął konto w międzyczasie), zwracamy ją
        if base_username.lower() not in existing_set:
            return base_username

        # Szukamy pierwszej wolnej liczby
        counter = 1
        while True:
            new_username = f"{base_username}{counter}"
            if new_username.lower() not in existing_set:
                return new_username
            counter += 1