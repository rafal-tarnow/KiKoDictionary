"""Add dual language support

Revision ID: d1bad2db3dce
Revises: f1635eaa4a21
Create Date: 2026-04-13 17:48:33.141121

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd1bad2db3dce'
down_revision: Union[str, Sequence[str], None] = 'f1635eaa4a21'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema and migrate existing data."""
    
    # KROK 1: Dodajemy nowe kolumny. 
    # UWAGA: Najpierw jako nullable=True, żeby baza nie wywaliła błędu, że dodajemy pustą kolumnę do istniejących wierszy.
    with op.batch_alter_table('sentences', schema=None) as batch_op:
        batch_op.add_column(sa.Column('original_text', sa.String(length=569), nullable=True))
        batch_op.add_column(sa.Column('translated_text', sa.String(length=569), nullable=True))
        batch_op.add_column(sa.Column('source_language', sa.String(length=10), nullable=True))
        batch_op.add_column(sa.Column('target_language', sa.String(length=10), nullable=True))

    # KROK 2: MIGRACJA DANYCH (To ratuje Twoje zdania!)
    # Tutaj realizujemy Twoje wymaganie: source_language staje się 'pl'.
    # A stare 'language' (które pewnie było 'en') przechodzi do 'target_language'.
    op.execute("""
        UPDATE sentences 
        SET original_text = sentence,
            translated_text = translation,
            source_language = 'pl',
            target_language = language
    """)

    # KROK 3: Sprzątanie i rygor bazy danych
    # Zmieniamy kolumny na NOT NULL, bo teraz już mają przypisane dane, i usuwamy stare kolumny.
    with op.batch_alter_table('sentences', schema=None) as batch_op:
        # Wymuszamy NOT NULL
        batch_op.alter_column('original_text', existing_type=sa.String(length=569), nullable=False)
        batch_op.alter_column('translated_text', existing_type=sa.String(length=569), nullable=False)
        batch_op.alter_column('source_language', existing_type=sa.String(length=10), nullable=False)
        batch_op.alter_column('target_language', existing_type=sa.String(length=10), nullable=False)
        
        # Tworzymy nowe indeksy
        batch_op.create_index(batch_op.f('ix_sentences_original_text'), ['original_text'], unique=False)
        batch_op.create_index(batch_op.f('ix_sentences_source_language'), ['source_language'], unique=False)
        batch_op.create_index(batch_op.f('ix_sentences_target_language'), ['target_language'], unique=False)

        # Usuwamy stare indeksy i kolumny
        batch_op.drop_index('ix_sentences_language')
        batch_op.drop_index('ix_sentences_sentence')
        batch_op.drop_column('translation')
        batch_op.drop_column('sentence')
        batch_op.drop_column('language')


def downgrade() -> None:
    """Downgrade schema and restore data."""
    
    # KROK 1: Przywracamy stare kolumny (nullable=True)
    with op.batch_alter_table('sentences', schema=None) as batch_op:
        batch_op.add_column(sa.Column('language', sa.VARCHAR(), nullable=True))
        batch_op.add_column(sa.Column('sentence', sa.VARCHAR(), nullable=True))
        batch_op.add_column(sa.Column('translation', sa.VARCHAR(), nullable=True))

    # KROK 2: Kopiujemy dane z powrotem, w razie wycofania (rollback) zmian
    op.execute("""
        UPDATE sentences 
        SET sentence = original_text,
            translation = translated_text,
            language = target_language
    """)

    # KROK 3: Usuwamy nowe elementy
    with op.batch_alter_table('sentences', schema=None) as batch_op:
        batch_op.create_index('ix_sentences_sentence', ['sentence'], unique=False)
        batch_op.create_index('ix_sentences_language', ['language'], unique=False)
        
        batch_op.drop_index(batch_op.f('ix_sentences_target_language'))
        batch_op.drop_index(batch_op.f('ix_sentences_source_language'))
        batch_op.drop_index(batch_op.f('ix_sentences_original_text'))
        
        batch_op.drop_column('target_language')
        batch_op.drop_column('source_language')
        batch_op.drop_column('translated_text')
        batch_op.drop_column('original_text')

