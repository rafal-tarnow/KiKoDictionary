FROM python:3.12-slim

WORKDIR /app

# Instalacja poetry
RUN pip install --no-cache-dir poetry

# Nie chcemy wirtualnych środowisk wewnątrz dockera, bo sam kontener to izolacja
RUN poetry config virtualenvs.create false

COPY pyproject.toml poetry.lock* ./

# Instalujemy zależności bez głównego pakietu (szybciej buduje cache)
RUN poetry install --only main --no-root

COPY . .

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8002"]
