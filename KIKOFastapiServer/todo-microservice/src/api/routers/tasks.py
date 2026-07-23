from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from src.db.database import get_db
from src.schemas.task import TaskCreate, TaskUpdate, TaskResponse, TaskReorder
from src.api.dependencies import get_current_user, CurrentUser
from src.crud.task_repo import TaskRepository

router = APIRouter(prefix="/api/v1/tasks", tags=["Tasks"])

# Funkcja pomocnicza tworząca instancję repozytorium (Dependency Injection)
def get_task_repo(db: AsyncSession = Depends(get_db)) -> TaskRepository:
    return TaskRepository(db)

@router.get("/", response_model=List[TaskResponse])
async def get_tasks(
    current_user: CurrentUser = Depends(get_current_user),
    repo: TaskRepository = Depends(get_task_repo)
):
    return await repo.get_user_tasks(current_user.id)

@router.post("/", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_task(
    task_in: TaskCreate,
    current_user: CurrentUser = Depends(get_current_user),
    repo: TaskRepository = Depends(get_task_repo)
):
    return await repo.create_task(current_user.id, task_in)

@router.put("/{task_id}", response_model=TaskResponse)
async def update_task(
    task_id: int,
    task_in: TaskUpdate,
    current_user: CurrentUser = Depends(get_current_user),
    repo: TaskRepository = Depends(get_task_repo)
):
    return await repo.update_task(current_user.id, task_id, task_in)

@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(
    task_id: int,
    current_user: CurrentUser = Depends(get_current_user),
    repo: TaskRepository = Depends(get_task_repo)
):
    await repo.delete_task(current_user.id, task_id)

@router.post("/{task_id}/reorder", response_model=TaskResponse)
async def reorder_task(
    task_id: int,
    reorder_data: TaskReorder,
    current_user: CurrentUser = Depends(get_current_user),
    repo: TaskRepository = Depends(get_task_repo)
):
    """
    Endpoint wywoływany, gdy użytkownik "upuści" zadanie (Drag & Drop) we Flutterze.
    """
    return await repo.reorder_task(
        user_id=current_user.id,
        task_id=task_id,
        prev_id=reorder_data.prev_task_id,
        next_id=reorder_data.next_task_id
    )