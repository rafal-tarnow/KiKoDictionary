#!/bin/bash

# Zatrzymanie skryptu w przypadku błędu (opcjonalne, ale zalecane)
set -e 

# 1. Zapamiętaj katalog, z którego uruchamiasz skrypt (zakładamy, że to root projektu)
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

git pull origin main

sudo systemctl stop maia-sentences.service
sudo systemctl stop maia-users.service
sudo systemctl stop maia-captcha.service


cd "$BASE_DIR/captcha-microservice/systemd_files"
chmod +x install_systemd_service.sh
sudo ./install_systemd_service.sh
cd "$BASE_DIR/captcha-microservice"
sudo rm -f -r .venv
python3 -m venv .venv
./.venv/bin/pip install --upgrade pip
./.venv/bin/pip install -r requirements.txt


cd "$BASE_DIR/sentences-microservice/systemd_files"
chmod +x install_systemd_service.sh
sudo ./install_systemd_service.sh
cd "$BASE_DIR/sentences-microservice"
sudo rm -f -r .venv
python3 -m venv .venv
./.venv/bin/pip install --upgrade pip
./.venv/bin/pip install -r requirements.txt


cd "$BASE_DIR/users-microservice/systemd_files"
chmod +x install_systemd_service.sh
sudo ./install_systemd_service.sh
cd "$BASE_DIR/users-microservice"
sudo rm -f -r .venv
poetry config virtualenvs.in-project true
export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
poetry -v install --no-root


# --- START SERWISÓW ---
echo "Restartowanie serwisów..."

# POPRAWKA: Przeładowanie systemd po zmianie plików .service
sudo systemctl daemon-reload

sudo systemctl enable maia-captcha.service
sudo systemctl enable maia-sentences.service
sudo systemctl enable maia-users.service

sudo systemctl restart maia-captcha.service
sudo systemctl restart maia-sentences.service
sudo systemctl restart maia-users.service

echo "Gotowe!"
