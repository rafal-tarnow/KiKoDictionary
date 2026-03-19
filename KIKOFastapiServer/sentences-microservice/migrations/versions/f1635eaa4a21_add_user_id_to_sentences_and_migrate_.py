"""Add user_id to sentences and migrate data

Revision ID: f1635eaa4a21
Revises: 
Create Date: 2026-03-13 18:14:47.952621

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import table, column # Dodane do aktualizacji danych


# revision identifiers, used by Alembic.
revision: str = 'f1635eaa4a21'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Używamy batch_alter_table, bo SQLite ma ograniczenia dotyczące zmiany kolumn (np. dodawanie NOT NULL)
    with op.batch_alter_table('sentences', schema=None) as batch_op:
        # 1. Dodajemy kolumnę, ale tymczasowo z nullable=True, żeby SQLite nie panikował
        batch_op.add_column(sa.Column('user_id', sa.String(), nullable=True))

    # 2. Migracja Danych: Aktualizujemy stare wpisy o Twoje ID
    # Tworzymy tymczasową reprezentację tabeli, by użyć jej w zapytaniu UPDATE
    sentences_table = table('sentences', column('user_id', sa.String))
    op.execute(
        sentences_table.update().values(
            user_id='839badd4-7ae0-4caa-b55f-9cb47899804c'
        )
    )

    # 3. Zmiana na NOT NULL oraz ewentualna poprawka typu created_at
    with op.batch_alter_table('sentences', schema=None) as batch_op:
        # Wymuszamy, by kolumna user_id od tej pory nie przyjmowała wartości NULL
        batch_op.alter_column('user_id', existing_type=sa.String(), nullable=False)
        # Przebudowujemy kolumnę created_at na świadomą strefy (nawet w SQLite warto to wymusić na poziomie ORM)
        batch_op.alter_column('created_at', type_=sa.DateTime(timezone=True), existing_type=sa.DateTime())
        # Tworzymy indeks na user_id dla szybszego wyszukiwania
        batch_op.create_index(batch_op.f('ix_sentences_user_id'), ['user_id'], unique=False)


def downgrade() -> None:
    with op.batch_alter_table('sentences', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_sentences_user_id'))
        batch_op.drop_column('user_id')
        batch_op.alter_column('created_at', type_=sa.DateTime(), existing_type=sa.DateTime(timezone=True))