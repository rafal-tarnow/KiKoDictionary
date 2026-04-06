from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from sqlalchemy import or_, func
from datetime import datetime, timezone
import uuid
import re
from coolname import generate_slug
import random

from src.db.models.user import User
from src.db.models.user_profile import UserProfile
from src.api.v1.schemas.user import UserCreate
from src.core.security import get_password_hash


class UserRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def get_by_email(self, email: str) -> Optional[User]:
        email_lower = email.lower()
        # [ZMIANA]: Pobieramy tylko aktywnych użytkowników
        result = await self.db.execute(
            select(User).filter(User.email == email_lower, User.is_active == True)
        )
        return result.scalars().first()
    

    async def get_by_username(self, username: str) -> Optional[User]:
        """
        Wyszukuje użytkownika ignorując wielkość liter.
        Dla wejścia 'tom' znajdzie użytkownika 'Tom'.
        """
        username_lower = username.lower()
        # [ZMIANA]: Pobieramy tylko aktywnych użytkowników
        result = await self.db.execute(
            select(User).filter(
                func.lower(User.username) == username_lower,
                User.is_active == True
            )
        )
        return result.scalars().first()
    
    async def get_by_id(self, user_id: str) -> Optional[User]:
        # [ZMIANA UWAGA]: Celowo nie sprawdzamy tu is_active, 
        # bo system może potrzebować pobrać usuniętego usera np. żeby wyświetlić "Konto Usunięte" w komentarzach.
        # aby SQLAlchemy od razu pobrało tabelę user_profiles (wydajność!)
        result = await self.db.execute(
            select(User)
            .options(selectinload(User.profile))
            .filter(User.id == user_id)
        )
        return result.scalars().first()
    

    async def get_by_email_or_username(self, identifier: str) -> Optional[User]:
        """
        Logowanie: Sprawdza czy identyfikator pasuje do emaila lub username
        (w obu przypadkach case-insensitive).
        """
        identifier_lower = identifier.lower()
        # Szukamy po emailu LUB po username (ignorując wielkość liter w obu przypadkach)
        # [ZMIANA]: Pobieramy tylko aktywnych użytkowników
        result = await self.db.execute(
            select(User).filter(
                or_(
                    User.email == identifier_lower,
                    func.lower(User.username) == identifier_lower
                ),
                User.is_active == True
            )
        )
        return result.scalars().first()
    

    async def _generate_unique_username(self) -> str:
        """
        Generuje przyjazny dla ucha, unikalny login (np. CleverTiger842).
        Gwarantuje unikalność poprzez odpytanie bazy danych w pętli.
        """
        while True:
            # Generuje 2 losowe, ładne słowa, usuwa myślniki i robi CamelCase
            # np. "brave-panther" -> "BravePanther"
            base_slug = generate_slug(2).title().replace("-", "")
            
            # Dodaje losowy sufix liczbowy dla gwarancji unikalności
            suffix = random.randint(100, 9999)
            candidate = f"{base_slug}{suffix}"
            
            # Sprawdzenie czy w bazie już istnieje taki sam
            exists = await self.get_by_username(candidate)
            if not exists:
                return candidate
            

    async def suggest_available_usernames(self, base_username: str, limit: int = 3) -> list[str]:
        """
        Zwraca listę wolnych nazw użytkownika bazujących na wpisanym słowie.
        Wysyła tylko JEDNO zapytanie do bazy (wydajność!).
        """
        suggestions = []
        candidates = set()
        
        # 1. Tworzymy pulę np. 10 kandydatów (z krótkimi sufixami)
        while len(candidates) < 10:
            suffix = random.randint(10, 999)
            candidates.add(f"{base_username}{suffix}")
            
        # 2. Odpytujemy bazę JEDNYM ZAPYTANIEM o wszystkie te nazwy naraz
        query = select(User.username).filter(
            func.lower(User.username).in_([c.lower() for c in candidates])
        )
        result = await self.db.execute(query)
        taken_usernames = {u.lower() for u in result.scalars().all()}
        
        # 3. Zwracamy tylko te, których baza NIE znalazła
        for candidate in candidates:
            if candidate.lower() not in taken_usernames:
                suggestions.append(candidate)
                if len(suggestions) == limit:
                    break
                    
        return suggestions


    async def create(self, user_data: UserCreate) -> User:
        hashed_password = get_password_hash(user_data.password)
        
        generated_username = await self._generate_unique_username()
        
        db_user = User(
            username=generated_username, 
            email=user_data.email.lower(),
            hashed_password=hashed_password,
        )
        
        self.db.add(db_user)
        # 1. Zapisujemy Usera, aby dostać jego ID
        await self.db.flush()

        # 2. Tworzymy Profil przypięty do tego ID
        db_profile = UserProfile(user_id=db_user.id)
        self.db.add(db_profile)

        # 3. Pełny commit transakcji
        await self.db.commit()
        
        # ================= ZMIANA (NAPRAWA BŁĘDU MissingGreenlet) =================
        # Zamiast odpalać kolejne ciężkie zapytanie SQL przez selectinload (co wiesza asyncio w testach),
        # po prostu "ręcznie" dopinamy dopiero co stworzony profil do obiektu db_user.
        await self.db.refresh(db_user)
        await self.db.refresh(db_profile)
        db_user.profile = db_profile
        
        return db_user
    

    async def update(self, user: User) -> User:
        """
        Zapisuje zmiany dokonane na obiekcie użytkownika.
        """
        self.db.add(user) # Oznaczamy obiekt jako "do zapisania"
        await self.db.commit() # Fizyczny zapis w bazie
        await self.db.refresh(user) # Odświeżenie danych (np. updated_at)
        return user


    # --- [ZMIANA]: NOWA METODA - PROFESJONALNE USUWANIE KONTA ---
    async def soft_delete_user(self, user: User) -> None:
        """
        Soft Delete + Anonimizacja danych (Zgodność z RODO/GDPR).
        Zwalnia email i username dla przyszłych rejestracji innych osób.
        """
        random_suffix = uuid.uuid4().hex[:8]
        
        # 1. Anonimizacja danych wrażliwych
        # email musi być unikalny, więc dodajemy UUID, ale wciąż musi mieć format maila wg Pydantic (jeśli gdzieś validujemy baze)
        user.email = f"deleted_{user.id}@anonymized.local" 
        # Zmieniamy username, by uwolnić oryginalny nick
        user.username = f"DeletedUser_{random_suffix}" 
        # Kasujemy hasło, nikt się już nie zaloguje
        user.hashed_password = "DELETED_ACCOUNT" 
        
        # 2. Ustawienie flag usunięcia
        user.is_active = False
        user.deleted_at = datetime.now(timezone.utc)

        # Zapis do bazy
        self.db.add(user)
        await self.db.commit()