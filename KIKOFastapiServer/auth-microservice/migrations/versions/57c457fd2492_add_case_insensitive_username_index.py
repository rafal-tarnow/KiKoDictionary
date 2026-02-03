"""add case insensitive username index

Revision ID: 57c457fd2492
Revises: 82e631a4ad32
Create Date: 2026-02-02 20:58:58.583350

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '57c457fd2492'
down_revision: Union[str, None] = '82e631a4ad32'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # 1. Modyfikujemy tylko tabelę users
    with op.batch_alter_table('users', schema=None) as batch_op:
        # Usuwamy stary, zwykły indeks (case-sensitive)
        # UWAGA: Upewnij się, że nazwa 'ix_users_username' jest poprawna. 
        # Jeśli masz wątpliwości, sprawdź w DB Browser for SQLite lub innym narzędziu.
        batch_op.drop_index('ix_users_username')

        # 2. Tworzymy nowy indeks funkcyjny (case-insensitive)
        # Ręcznie dodajemy sa.text('lower(username)')
        batch_op.create_index(
            'ix_users_username_lower',
            [sa.text('lower(username)')], 
            unique=True
        )


def downgrade() -> None:
    """Downgrade schema."""
    with op.batch_alter_table('users', schema=None) as batch_op:
        # Usuwamy nasz nowy indeks
        batch_op.drop_index('ix_users_username_lower')

        # Przywracamy stary indeks
        batch_op.create_index('ix_users_username', ['username'], unique=True)