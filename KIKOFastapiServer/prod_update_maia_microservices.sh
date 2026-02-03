#!/bin/bash

# 1. Zatrzymaj serwisy
sudo systemctl stop maia-captcha.service
sudo systemctl stop maia-sentences.service
sudo systemctl stop maia-auth.service

# 2. Pobierz zmiany
cd ~/Documents/GITHUB_MOJE/KiKoDictionary
git pull origin main

# --- Serwis 1 (PIP) ---
cd ~/Documents/GITHUB_MOJE/KiKoDictionary/KIKOFastapiServer/captcha-microservice
# Usunąłem "python3 -m venv...", bo venv już tam jest
source .venv/bin/activate
pip install -r requirements.txt
alembic upgrade head			#upgrade databade
deactivate

# --- Serwis 2 (PIP) ---
cd ~/Documents/GITHUB_MOJE/KiKoDictionary/KIKOFastapiServer/sentences-microservice
source .venv/bin/activate
pip install -r requirements.txt
alembic upgrade head			#upgrade databade
deactivate

# --- Serwis 3 (POETRY) ---
cd ~/Documents/GITHUB_MOJE/KiKoDictionary/KIKOFastapiServer/auth-microservice
# Poetry samo ogarnie środowisko, jeśli naprawiłeś uprawnienia komendą chown
poetry install --only main --no-root --sync
poetry run alembic upgrade head		#upgrade databade

# 3. Wystartuj serwisy
sudo systemctl start maia-captcha.service
sudo systemctl start maia-auth.service
sudo systemctl start maia-sentences.service

echo "Upgrade wdrożenia zakończone sukcesem!"
