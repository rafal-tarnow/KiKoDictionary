from typing import Optional
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from src.db.models.password_reset import PasswordResetToken

class PasswordResetRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def create(self, user_id: str, token: str, expires_at: datetime) -> PasswordResetToken:
        # Opcjonalnie: Możesz tu najpierw unieważnić poprzednie niewykorzystane tokeny tego usera
        db_token = PasswordResetToken(
            user_id=user_id,
            token=token,
            expires_at=expires_at,
            is_used=False
        )
        self.db.add(db_token)
        await self.db.commit()
        await self.db.refresh(db_token)
        return db_token

    async def get_valid_token(self, token: str) -> Optional[PasswordResetToken]:
        """
        Pobiera token, jeśli istnieje, nie został użyty i nie wygasł.
        """
        query = select(PasswordResetToken).filter(
            PasswordResetToken.token == token,
            PasswordResetToken.is_used == False,
            PasswordResetToken.expires_at > datetime.now(timezone.utc)
        )
        result = await self.db.execute(query)
        return result.scalars().first()

    async def mark_as_used(self, token_id: str) -> None:
        db_token = await self.db.get(PasswordResetToken, token_id)
        if db_token:
            db_token.is_used = True
            await self.db.commit()