FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Instalacja poetry
RUN pip install --no-cache-dir poetry

# W Dockerze nie chcemy wirtualnych srodowisk - kontener to izolacja
RUN poetry config virtualenvs.create false

# Najpierw tylko pliki zaleznosci (cache warstw Dockera)
COPY pyproject.toml poetry.lock* ./
RUN poetry install --only main --no-root

COPY . .

EXPOSE 8005

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8005/health/live', timeout=3)" || exit 1

# Przy kazdym starcie kontenera dociagamy schemat bazy do najnowszej migracji,
# dopiero potem startuje API (exec -> uvicorn dostaje sygnaly zamiast powloki).
CMD ["sh", "-c", "alembic upgrade head && exec uvicorn src.main:app --host 0.0.0.0 --port 8005"]
