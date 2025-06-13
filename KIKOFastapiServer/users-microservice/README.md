# Users & Authentication Microservice

Ten mikroserwis jest odpowiedzialny za zarządzanie cyklem życia użytkownika, w tym rejestrację, logowanie oraz autoryzację za pomocą tokenów JWT. Jest częścią większego systemu do nauki języków.

## Kluczowe Cechy

- **FastAPI**: Wysokowydajny, asynchroniczny framework webowy.
- **Czysta Architektura**: Podział na warstwy (API, Usługi, Repozytoria) dla łatwej konserwacji i testowania.
- **JWT**: Standardowa autoryzacja za pomocą `access` i `refresh` tokenów.
- **Gotowość na Cache**: Wzorzec Repozytorium pozwala na łatwe dodanie warstwy cache (np. Redis) bez modyfikacji logiki biznesowej.
- **Gotowość na Chmurę**: Konfiguracja przez zmienne środowiskowe, bezstanowość.
- **Integracja z CAPTCHA**: Zabezpieczenie endpointów rejestracji i logowania.
- **Testy**: Zestaw testów jednostkowych i integracyjnych przy użyciu `pytest`.

## Struktura Projektu

users_service/
├── .env.example # Przykładowa konfiguracja
├── pyproject.toml # Definicje projektu i zależności (Poetry)
├── README.md # Ta dokumentacja
├── src/ # Główny kod źródłowy aplikacji
└── tests/ # Testy


## 1. Instalacja

### Wymagania
- Python 3.10+
- [Poetry](https://python-poetry.org/docs/#installation)

### Kroki

1.  **Sklonuj repozytorium:**
    ```bash
    git clone <adres_repozytorium>
    cd users_service
    ```

2.  **Zainstaluj zależności za pomocą Poetry:**

    poetry install
    
    Spowoduje to utworzenie wirtualnego środowiska i zainstalowanie wszystkich pakietów z `pyproject.toml`.

3.  **Skonfiguruj zmienne środowiskowe:**
    Skopiuj plik `.env.example` do nowego pliku o nazwie `.env`:
    ```bash
    cp .env.example .env
    ```
    Otwórz plik `.env` i dostosuj wartości, zwłaszcza `SECRET_KEY` i `CAPTCHA_SERVICE_URL`.

## 2. Uruchomienie Serwisu

Aby uruchomić serwer deweloperski z automatycznym przeładowaniem:

poetry run uvicorn src.main:app --reload --port 8002