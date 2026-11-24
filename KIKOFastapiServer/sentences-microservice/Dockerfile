FROM python:3.12-slim

# pip jako root w kontenerze jest zamierzony (kontener = izolacja) - bez ostrzezenia przy budowaniu
ENV PIP_ROOT_USER_ACTION=ignore

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Przy starcie kontenera schemat bazy jest dociągany do najnowszej migracji, potem startuje API
CMD ["sh", "-c", "alembic upgrade head && exec uvicorn main:app --host 0.0.0.0 --port 8003"]
