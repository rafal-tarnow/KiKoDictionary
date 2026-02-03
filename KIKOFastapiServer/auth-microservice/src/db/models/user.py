import uuid
import enum
from sqlalchemy import Column, String, DateTime, func, Enum, Index
from sqlalchemy.orm import declarative_base

Base = declarative_base()

class AccountSubscription(str, enum.Enum):
    FREE = "FREE"
    PRO = "PRO"

class AccountRole(str, enum.Enum):
    ADMIN = "ADMIN"
    MODERATOR = "MODERATOR"
    REGULAR = "REGULAR"

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    # Usuwamy index=True stąd, bo dodajemy niestandardowy index poniżej
    username = Column(String, unique=False, nullable=False) 
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    
    account_role = Column(Enum(AccountRole), default=AccountRole.REGULAR, nullable=False)

    account_subscription = Column(Enum(AccountSubscription), default=AccountSubscription.FREE, nullable=False)
    subscription_expires_at = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # --- PROFESJONALNE ZABEZPIECZENIE ---
    __table_args__ = (
        # 1. Unikalny index na małych literach username.
        # To gwarantuje, że 'Tom' i 'tom' nie mogą istnieć obok siebie w bazie.
        # Jest to najwydajniejszy sposób na case-insensitive uniqueness.
        Index('ix_users_username_lower', func.lower(username), unique=True),
        
        # 2. Zwykły index dla username (opcjonalny, jeśli często szukamy case-sensitive, ale rzadko to robimy)
        # W tym modelu index funkcyjny wyżej załatwia większość spraw.
    )