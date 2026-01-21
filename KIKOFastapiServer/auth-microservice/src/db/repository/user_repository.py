from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from src.db.models.user import User
from src.api.v1.schemas.user import UserCreate
from src.core.security import get_password_hash

class UserRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def get_by_email(self, email: str) -> Optional[User]:
        result = await self.db.execute(select(User).filter(User.email == email))
        return result.scalars().first()
    
    async def get_by_username(self, username: str) -> Optional[User]:
        result = await self.db.execute(select(User).filter(User.username == username))
        return result.scalars().first()
    
    async def get_by_id(self, user_id: str) -> Optional[User]:
        result = await self.db.execute(select(User).filter(User.id == user_id))
        return result.scalars().first()
    
    async def create(self, user_data: UserCreate) -> User:
        hashed_password = get_password_hash(user_data.password)
        db_user = User(
            username=user_data.username,
            email=user_data.email,
            hashed_password=hashed_password,
            )
        self.db.add(db_user)
        await self.db.commit()
        await self.db.refresh(db_user)
        return db_user