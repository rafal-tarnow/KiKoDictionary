"""Add manual ordering (position) to sentences

Revision ID: a7c3e9f2b1d4
Revises: d0933a804317
Create Date: 2026-11-24 16:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a7c3e9f2b1d4'
down_revision: Union[str, Sequence[str], None] = 'd0933a804317'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

POSITION_STEP = 1000.0


def upgrade() -> None:
    """Upgrade schema."""
    with op.batch_alter_table('sentences', schema=None) as batch_op:
        batch_op.add_column(sa.Column('position', sa.Float(), server_default='0', nullable=False))

    # Istniejące zdania dostają kolejność taką, jaką użytkownik widział do tej pory:
    # najnowsze na górze (pozycja 1000, 2000, 3000... osobno dla każdego usera).
    op.execute(
        f"""
        UPDATE sentences SET position = (
            SELECT ranked.rn * {POSITION_STEP}
            FROM (
                SELECT id, ROW_NUMBER() OVER (
                    PARTITION BY user_id ORDER BY created_at DESC, id DESC
                ) AS rn
                FROM sentences
            ) AS ranked
            WHERE ranked.id = sentences.id
        )
        """
    )

    with op.batch_alter_table('sentences', schema=None) as batch_op:
        batch_op.create_index('ix_sentences_user_position', ['user_id', 'position'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    with op.batch_alter_table('sentences', schema=None) as batch_op:
        batch_op.drop_index('ix_sentences_user_position')
        batch_op.drop_column('position')
