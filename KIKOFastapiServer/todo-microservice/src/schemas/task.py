from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from typing import Optional

class TaskCreate(BaseModel):
    content: str = Field(..., min_length=1, max_length=500, description="Task content in English")

class TaskUpdate(BaseModel):
    content: Optional[str] = Field(None, min_length=1, max_length=500)
    is_completed: Optional[bool] = None

class TaskReorder(BaseModel):
    # ID zadań, pomiędzy które chcemy wstawić nasze zadanie (jedno z nich może być None, jeśli wstawiamy na samą górę/dół)
    prev_task_id: Optional[int] = None
    next_task_id: Optional[int] = None

class TaskResponse(BaseModel):
    id: int
    content: str
    is_completed: bool
    position: float
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)