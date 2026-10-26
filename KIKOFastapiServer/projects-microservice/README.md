# Projects microservice (port 8005)

Dwupoziomowa lista zadań: **projekty → zadania**. Kolejność projektów i zadań
ustawia się przeciąganiem (drag & drop). Frontend: pozycja **Projects** w drawerze
aplikacji Flutter (`client/maia_flutter_client/lib/features/projects`).

Serwis nie ma własnych użytkowników — weryfikuje tokeny JWT wystawione przez
`auth-microservice` (ten sam `SECRET_KEY` / `ALGORITHM`, claim `sub` = ID usera).

## Architektura

```
src/
├── main.py                 # create_app(): middleware, routery, handlery błędów
├── core/                   # konfiguracja, JWT, wyjątki domenowe -> HTTP
├── db/                     # Base, sesja (async), typy (UTC), modele ORM
├── repositories/           # dostęp do danych (SQL) – bez logiki biznesowej
├── services/               # logika biznesowa + algorytm sortowania (ordering.py)
├── schemas/                # kontrakty API (Pydantic) – request / response
└── api/                    # routery FastAPI (cienkie), zależności (DI), health
migrations/                 # Alembic (schemat bazy)
tests/                      # pytest + httpx, baza SQLite w pamięci
```

Przepływ żądania: `router → service → repository → DB`. Serwisy rzucają wyjątki
domenowe (`src/core/exceptions.py`), a `exception_handlers.py` zamienia je na
odpowiedzi `{"detail": ..., "error_code": ...}`.

### Sortowanie (drag & drop)

Każdy element ma `position: float`. Po upuszczeniu elementu frontend wysyła ID
sąsiadów (`prev_id` – nad, `next_id` – pod), a serwer ustawia pozycję na średnią
sąsiadów → **jeden UPDATE na jedno przeciągnięcie**. Gdy przerwa między sąsiadami
stanie się zbyt mała (limit precyzji float), lista jest jednorazowo przenumerowana.
Serwer sam dobiera drugiego sąsiada, więc lekko nieaktualna lista po stronie
klienta nie psuje kolejności.

## API (`/api/v1`, wymagany nagłówek `Authorization: Bearer <access_token>`)

| Metoda | Ścieżka | Opis |
|---|---|---|
| GET | `/projects` | lista projektów (z `task_count`, `completed_task_count`) |
| POST | `/projects` | nowy projekt (`name`, `description?`, `color?` `#RRGGBB`) |
| GET / PATCH / DELETE | `/projects/{id}` | odczyt / częściowa edycja / usunięcie (razem z zadaniami) |
| POST | `/projects/{id}/reorder` | `{"prev_id": 1, "next_id": 2}` |
| GET | `/projects/{id}/tasks` | lista zadań projektu |
| POST | `/projects/{id}/tasks` | nowe zadanie (`title`, `description?`, `priority?` none/low/medium/high, `due_date?` YYYY-MM-DD) |
| GET / PATCH / DELETE | `/projects/{id}/tasks/{task_id}` | odczyt / edycja (też `is_completed`) / usunięcie |
| POST | `/projects/{id}/tasks/{task_id}/reorder` | `{"prev_id": 1, "next_id": 2}` |
| GET | `/health/live`, `/health/ready` | liveness / readiness (sprawdza bazę) |

Swagger: http://127.0.0.1:8005/docs

W `PATCH` pole pominięte = bez zmian, `null` = wyczyść (tylko `description`, `due_date`).

## Pierwsze uruchomienie lokalnie (Windows)

```powershell
cd KIKOFastapiServer/projects-microservice
Copy-Item .env.example .env        # uzupełnij SECRET_KEY taki sam jak w auth / todo
py -m venv .venv
poetry env use .\.venv\Scripts\python.exe   # WAŻNE: inaczej poetry może instalować do globalnego Pythona
poetry install
poetry run alembic upgrade head
poetry run uvicorn src.main:app --host 127.0.0.1 --port 8005 --reload
```

Kolejne uruchomienia:

```powershell
poetry run uvicorn src.main:app --host 127.0.0.1 --port 8005 --reload
```

## Testy

```powershell
poetry run pytest
```

## Docker

Serwis jest w `../docker-compose.yml` jako `projects` (kontener `maia-projects`).
Baza: `../databases/projects.db`. Przy starcie kontenera automatycznie wykonuje się
`alembic upgrade head`.

```bash
docker compose up -d --build projects
```

Dostęp z internetu: w panelu Cloudflare Zero Trust dodaj do tunelu
public hostname (np. `dev-projects.rafal-kruszyna.org`) → `http://projects:8005`.

## Migracje bazy

1. Zmień / dodaj model w `src/db/models/` (nowy model zaimportuj w `src/db/models/__init__.py`).
2. `poetry run alembic revision --autogenerate -m "opis zmiany"`
3. Przejrzyj wygenerowany plik w `migrations/versions/`.
4. `poetry run alembic upgrade head`
