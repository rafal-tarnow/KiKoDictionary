

PYTHONPATH=. poetry run pytest

poetry run uvicorn src.main:app --reload --port 8003

## Migracja bazy danych
poetry add alembic
poetry install
poetry run alembic init migrations
edit file alembic.init
edit file migrations/env.py
poetry run alembic revision --autogenerate -m "Update User model"
poetry run alembic upgrade head
akualizacja bazy sie nie udała bo w sqlite nie ma komendy alter, trzeba było wyedytowac plik migracji
poetry run alembic upgrade head