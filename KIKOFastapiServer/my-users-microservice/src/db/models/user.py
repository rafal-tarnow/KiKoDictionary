import uuid
import enum
from sqlalchemy import Column, String, DateTime, func, Enum
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
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    
    account_role = Column(Enum(AccountRole), default=AccountRole.REGULAR, nullable=False)

    account_subscription = Column(Enum(AccountSubscription), default=AccountSubscription.FREE, nullable=False)
    subscription_expires_at = Column(DateTime, nullable=True)

    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)