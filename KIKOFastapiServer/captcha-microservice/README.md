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

## Run
source venv_cap/bin/activate
uvicorn src.main:app --host 127.0.0.1 --port 8001

## Test captcha
open CaptchaQtTester form repo/KIKOFastapiServer/test_microservices_qt_apps/qt_test_captcha , start microservice as describled above, and run qt app

## Docs
http://127.0.0.1:8001/api/v1/docs