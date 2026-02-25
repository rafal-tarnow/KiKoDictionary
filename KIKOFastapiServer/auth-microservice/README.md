

## Run first time 
sudo apt install python3-poetry
poetry config virtualenvs.in-project true

Najczęstszym powodem zawieszania się Poetry na "Pending..." podczas pracy przez SSH jest Keyring (systemowy pęk kluczy) dlatego:

export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
poetry install


## Run

poetry run uvicorn src.main:app --reload --port 8002

## Run tests

PYTHONPATH=. poetry run pytest



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

## Migracja bazy danych
migracja, dodanie indeksu funkcyjnego na kolumne username w tabeli users, w celu rozwiania problemu ze Tom == tom (username case insensitive)

poetry run alembic revision --autogenerate -m "add case insensitive username index"

potem na prod i dev 
usunac dublujace sie indexy
a nastepnie:

poetry run alembic upgrade head

### Wygenerowanie nowej migracji
krok 1. jezeli utworzono nowa tabele w modelach to w pliku migrations/env.py dodać linie np.from src.db.models.password_reset import PasswordResetToken
, w tym pliku dodajemy wszyskie importy z tabelami zeby alembic wiedzial jakie tabele sa potrzebne
krok 2. alembic revision --autogenerate -m "add_soft_delete_to_user"
krok 3. przejrzeć plikc migracji cat ./migrations/versions/21befe77be08_add_soft_delete_to_user.py



