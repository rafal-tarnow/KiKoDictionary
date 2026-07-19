FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Uruchamiamy na 0.0.0.0, aby port był widoczny na zewnątrz kontenera
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8001"]
