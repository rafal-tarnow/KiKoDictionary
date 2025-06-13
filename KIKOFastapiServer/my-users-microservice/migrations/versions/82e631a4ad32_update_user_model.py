"""Update User model

Revision ID: 82e631a4ad32
Revises: 
Create Date: 2025-06-13 14:44:17.004060

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
import enum

# revision identifiers, used by Alembic.
revision: str = '82e631a4ad32'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

class AccountRole(enum.Enum):
    ADMIN = "ADMIN"
    MODERATOR = "MODERATOR"
    REGULAR = "REGULAR"

class AccountSubscription(enum.Enum):
    FREE = "FREE"
    PRO = "PRO"

def upgrade() -> None:
    """Upgrade schema."""
    # Utwórz tymczasową tabelę z nowym schematem
    op.create_table(
        'users_temp',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('username', sa.String(), nullable=False),
        sa.Column('email', sa.String(), nullable=False),
        sa.Column('hashed_password', sa.String(), nullable=False),
        sa.Column('account_role', sa.Enum(AccountRole, name='accountrole'), nullable=False),
        sa.Column('account_subscription', sa.Enum(AccountSubscription, name='accountsubscription'), nullable=False),
        sa.Column('subscription_expires_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
    )

    # Skopiuj dane z istniejącej tabeli
    op.execute(
        """
        INSERT INTO users_temp (id, username, email, hashed_password, account_role, account_subscription, subscription_expires_at, created_at, updated_at)
        SELECT CAST(id AS TEXT), '', '', '', 'REGULAR', 'FREE', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        FROM users
        """
    )

    # Usuń starą tabelę
    op.drop_table('users')

    # Zmień nazwę tymczasowej tabeli
    op.rename_table('users_temp', 'users')

    # Dodaj indeksy
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)
    op.create_index(op.f('ix_users_username'), 'users', ['username'], unique=True)

def downgrade() -> None:
    """Downgrade schema."""
    # Utwórz tymczasową tabelę ze starym schematem
    op.create_table(
        'users_temp',
        sa.Column('id', sa.NUMERIC(), primary_key=True),
    )

    # Skopiuj dane z powrotem
    op.execute(
        """
        INSERT INTO users_temp (id)
        SELECT CAST(id AS NUMERIC) FROM users
        """
    )

    # Usuń nową tabelę
    op.drop_table('users')

    # Zmień nazwę tymczasowej tabeli
    op.rename_table('users_temp', 'users')

    # Usuń indeks