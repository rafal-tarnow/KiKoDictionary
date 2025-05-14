# zapytania KIKODictionaryServer

# USERS
# curl "http://192.168.0.129:49425/api/users" --verbose
# curl "http://192.168.0.129:49425/api/users?page=2" --verbose

# curl "http://192.168.0.129:49425/api/unknown" --verbose
# curl "http://192.168.0.129:49425/api/unknown?page=2" --verbose
# curl "http://192.168.0.129:49425/api/unknown?page=2&per_page=4" --verbose

from fastapi import FastAPI, Query
from fastapi.staticfiles import StaticFiles
from typing import List, Dict
import random
import json
from pathlib import Path
from math import ceil
from datetime import datetime
from fastapi.middleware.cors import CORSMiddleware


from routers import sentence
from database import engine
from models.sentence import Base

# Tworzenie tabel w bazie danych
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Sentence Learning API")

# Zamontuj katalog assets/img pod ścieżką /img
app.mount("/img/faces", StaticFiles(directory="assets/img"), name="img")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {'example': 'This is an example', 'data': 999}

@app.get('/random')
async def get_random():
    rn: int = random.randint(0, 100)
    return {'number': rn, 'limit': 100}

@app.get('/json')
async def get_json_file():
    json_path = Path(__file__).parent / "data.json"
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    return data

def load_users_data() -> List[Dict]:
    json_path = Path(__file__).parent / "users.json"
    with open(json_path, "r", encoding="utf-8") as f:
        return json.load(f)

def load_colors_data() -> List[Dict]:
    json_path = Path(__file__).parent / "colors.json"
    with open(json_path, "r", encoding="utf-8") as f:
        return json.load(f)


def load_sentences_data() -> List[Dict]:
    json_path = Path(__file__).parent / "sentences.json"
    with open(json_path, "r", encoding="utf-8") as f:
        return json.load(f)


@app.get("/api/unknown")
async def get_colors(
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(10, ge=1, le=100, description="Items per page")
) -> Dict:
    all_colors = load_colors_data()
    total_items = len(all_colors)
    total_pages = ceil(total_items / per_page)

    if page > total_pages:
        page = total_pages if total_pages > 0 else 1

    start_idx = (page - 1) * per_page
    end_idx = start_idx + per_page

    paginated_colors = all_colors[start_idx:end_idx]

    return {
        "data": paginated_colors,
        "page": page,
        "per_page": per_page,
        "total": total_items,
        "total_pages": total_pages
    }


@app.get("/api/users")
async def get_users(
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(6, ge=1, le=100, description="Items per page")
) -> Dict:
    all_users = load_users_data()
    total_items = len(all_users)
    total_pages = ceil(total_items / per_page)

    if page > total_pages:
        page = total_pages if total_pages > 0 else 1

    start_idx = (page - 1) * per_page
    end_idx = start_idx + per_page

    current_time = datetime.utcnow().isoformat() + "Z"
    paginated_users = []
    for idx, user in enumerate(all_users[start_idx:end_idx], start=start_idx + 1):
        paginated_users.append({
            "id": idx,
            "email": user["email"],
            "first_name": user["first_name"],
            "last_name": user["last_name"],
            "avatar": f"http://127.0.0.1:8000{user['avatar']}",
            "createdAt": current_time,
            "updatedAt": current_time
        })

    return {
        "data": paginated_users,
        "page": page,
        "per_page": per_page,
        "total": total_items,
        "total_pages": total_pages
    }





# Rejestracja routerów
app.include_router(sentence.router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="192.168.0.129", port=8000)