from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import or_ 
from src.db.models.user import User
from src.api.v1.schemas.user import UserCreate
from src.core.security import get_password_hash

class UserRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def get_by_email(self, email: str) -> Optional[User]:
        # ZMIANA: .lower()
        # Nawet jeśli walidator Pydantic pominie coś (np. wywołanie wewnętrzne),
        # tutaj zabezpieczamy się przy odczycie.
        email_lower = email.lower()
        result = await self.db.execute(select(User).filter(User.email == email_lower))
        return result.scalars().first()
    
    async def get_by_username(self, username: str) -> Optional[User]:
        result = await self.db.execute(select(User).filter(User.username == username))
        return result.scalars().first()
    
    async def get_by_id(self, user_id: str) -> Optional[User]:
        result = await self.db.execute(select(User).filter(User.id == user_id))
        return result.scalars().first()
    
    async def get_by_email_or_username(self, identifier: str) -> Optional[User]:
        """
        Wyszukuje użytkownika sprawdzając czy podany identyfikator pasuje
        do adresu email (case-insensitive) LUB do nazwy użytkownika.
        """
        # ZMIANA: Logika obsługi logowania.
        # Skoro email w bazie jest ZAWSZE małą literą (dzięki Pydantic),
        # to szukając po emailu, musimy przekonwertować input na małe litery.
        
        identifier_lower = identifier.lower()

        # UWAGA: Tutaj jest niuans.
        # Jeśli 'identifier' to username, a username jest Case-Sensitive (na razie),
        # to nie powinniśmy go zmniejszać dla warunku username.
        # Ale dla warunku email - musimy.
        
        result = await self.db.execute(
            select(User).filter(
                or_(
                    User.email == identifier_lower,  # Szukamy jako email (małe litery)
                    User.username == identifier      # Szukamy jako username (oryginał)
                )
            )
        )
        return result.scalars().first()
    
    async def create(self, user_data: UserCreate) -> User:
        # Tutaj user_data.email jest już małą literą dzięki Pydanticowi,
        # więc nie musimy robić .lower() ponownie, ale dla pewności nie zaszkodzi.
        hashed_password = get_password_hash(user_data.password)
        db_user = User(
            username=user_data.username,
            email=user_data.email.lower(), # Double-check, dobra praktyka defensywna
            hashed_password=hashed_password,
        )
        self.db.add(db_user)
        await self.db.commit()
        await self.db.refresh(db_user)
        return db_user