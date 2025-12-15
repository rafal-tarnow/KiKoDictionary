from fastapi import APIRouter, Depends
from typing import Dict
from src.db.models.user import User as UserDb
from src.dependencies import get_current_user

router = APIRouter(prefix="/api/v1/data", tags=["Data"])

@router.get("/test-data", response_model=Dict[str, str])
async def get_test_data(current_user: UserDb = Depends(get_current_user)):
    return {"message": "This is protected test data", "user_id": str(current_user.id)}
