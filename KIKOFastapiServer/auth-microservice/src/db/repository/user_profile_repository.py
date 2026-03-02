from sqlalchemy.ext.asyncio import AsyncSession
from src.db.models.user_profile import UserProfile
from src.api.v1.schemas.user_profile import UserProfileUpdate

class UserProfileRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def update_profile(self, user_id: str, profile_data: UserProfileUpdate) -> UserProfile:
        from sqlalchemy.future import select
        
        # Pobieramy profil
        result = await self.db.execute(
            select(UserProfile).filter(UserProfile.user_id == user_id)
        )
        db_profile = result.scalars().first()

        if not db_profile:
            # Fallback (bezpieczeństwo): Gdyby z jakiegoś powodu profil nie istniał, twórzmy go w locie
            db_profile = UserProfile(user_id=user_id)
            self.db.add(db_profile)

        # Dynamiczna aktualizacja tylko tych pól, które zostały przysłane (nie są None)
        update_data = profile_data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_profile, key, value)

        await self.db.commit()
        await self.db.refresh(db_profile)
        return db_profile