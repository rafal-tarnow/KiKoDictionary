# First run (works on Windows)
1. Remove-Item -Recurse -Force .venv -ErrorAction SilentlyContinue
2. py -m venv .venv
3. .\.venv\Scripts\Activate.ps1
4. poetry install
5. uvicorn src.main:app --host 127.0.0.1 --port 8004 --reload

## Second (next) run (works on Windows)
1. .\.venv\Scripts\Activate.ps1
2. poetry run uvicorn src.main:app --host 127.0.0.1 --port 8004 --reload