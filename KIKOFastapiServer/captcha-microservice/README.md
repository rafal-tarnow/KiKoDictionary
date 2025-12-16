# CAPTCHA Microservice

A FastAPI-based microservice for generating CAPTCHA images.

## Prerequisites
- Docker
- Docker Compose
- Python 3.12 (for local development)

## Setup and Running

1. Clone the repository:
```bash
git clone <repository-url>
cd captcha_service

## First Run
python3 -m venv .venv_cap
source .venv_cap/bin/activate
pip install -r requirements.txt
uvicorn src.main:app --host 0.0.0.0 --port 8001

## Run
source .venv_cap/bin/activate
uvicorn src.main:app --host 0.0.0.0 --port 8001

## How to install app on new server
python3 -m venv .venv_cap
source .venv_cap/bin/activate
pip install -r requirements.txt
cd systemd_files
chmod +x install_systemd_service.sh
./install_systemd_service.sh
sudo systemctl start maia-captcha.service

sudo systemctl status maia-captcha.service

## Test captcha
open CaptchaQtTester form repo/KIKOFastapiServer/test_microservices_qt_apps/qt_test_captcha , start microservice as describled above, and run qt app

## Docs
http://127.0.0.1:8001/api/v1/docs

# Dump project to file
python dump_project.py