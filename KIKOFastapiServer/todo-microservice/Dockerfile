FROM python:3.12-slim

WORKDIR /app

# Instalacja poetry
RUN pip install --no-cache-dir poetry

# W Dockerze nie chcemy wirtualnych środowisk
RUN poetry config virtualenvs.create false

# Kopiujemy pliki konfiguracyjne poety (optymalizacja warstw Dockera)
COPY pyproject.toml poetry.lock* ./

# Instalujemy zależności bez pakietu deweloperskiego (szybciej buduje cache)
RUN poetry install --only main --no-root

# Kopiujemy resztę kodu
COPY . .

# Uruchamiamy na 0.0.0.0, na porcie 8004
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8004"]