from typing import Optional
from datetime import datetime
from sqlalchemy import delete
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload

from src.db.models.refresh_token import RefreshToken

class RefreshTokenRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def create(self, user_id: str, token: str, expires_at: datetime) -> RefreshToken:
        db_token = RefreshToken(
            user_id=user_id,
            refresh_token=token,
            expires_at=expires_at
        )
        self.db.add(db_token)
        await self.db.commit()
        await self.db.refresh(db_token)
        return db_token

    async def get_by_token(self, token: str) -> Optional[RefreshToken]:
        result = await self.db.execute(
            select(RefreshToken)
            .options(selectinload(RefreshToken.user)) # Opcjonalnie, aby załadować od razu dane usera
            .filter(RefreshToken.refresh_token == token)
        )
        return result.scalars().first()
    
    async def delete(self, token_id: str) -> None:
        db_token = await self.db.get(RefreshToken, token_id)
        if db_token:
            await self.db.delete(db_token)
            await self.db.commit()

    # Dodaj to na końcu klasy RefreshTokenRepository
    async def delete_all_for_user(self, user_id: str) -> None:
        """
        Usuwa wszystkie tokeny odświeżające danego użytkownika.
        Używane przy zmianie hasła, aby wylogować użytkownika ze wszystkich urządzeń.
        """
        # Importujemy delete wewnątrz metody lub na górze pliku
        from sqlalchemy import delete 
        
        stmt = delete(RefreshToken).where(RefreshToken.user_id == user_id)
        await self.db.execute(stmt)
        await self.db.commit()