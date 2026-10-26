from fastapi import APIRouter, status

from src.api.deps import CurrentUserDep, TaskServiceDep
from src.schemas import ErrorResponse, ReorderRequest, TaskCreate, TaskRead, TaskUpdate

# Zadania zawsze w kontekscie projektu: /projects/{project_id}/tasks/...
router = APIRouter(
    prefix="/projects/{project_id}/tasks",
    tags=["Project tasks"],
    responses={
        status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponse},
        status.HTTP_404_NOT_FOUND: {"model": ErrorResponse},
    },
)


@router.get("", response_model=list[TaskRead], summary="List project tasks (in display order)")
async def list_tasks(project_id: int, user: CurrentUserDep, service: TaskServiceDep) -> list[TaskRead]:
    return await service.list_tasks(user.id, project_id)


@router.post(
    "",
    response_model=TaskRead,
    status_code=status.HTTP_201_CREATED,
    summary="Create a task (appended to the end of the project)",
    responses={status.HTTP_409_CONFLICT: {"model": ErrorResponse}},
)
async def create_task(
    project_id: int, data: TaskCreate, user: CurrentUserDep, service: TaskServiceDep
) -> TaskRead:
    return await service.create_task(user.id, project_id, data)


@router.get("/{task_id}", response_model=TaskRead, summary="Get a task")
async def get_task(project_id: int, task_id: int, user: CurrentUserDep, service: TaskServiceDep) -> TaskRead:
    return await service.get_task(user.id, project_id, task_id)


@router.patch("/{task_id}", response_model=TaskRead, summary="Partially update a task")
async def update_task(
    project_id: int, task_id: int, data: TaskUpdate, user: CurrentUserDep, service: TaskServiceDep
) -> TaskRead:
    return await service.update_task(user.id, project_id, task_id, data)


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Delete a task")
async def delete_task(project_id: int, task_id: int, user: CurrentUserDep, service: TaskServiceDep) -> None:
    await service.delete_task(user.id, project_id, task_id)


@router.post(
    "/{task_id}/reorder",
    response_model=TaskRead,
    summary="Move a task between two neighbours (drag & drop)",
    responses={status.HTTP_400_BAD_REQUEST: {"model": ErrorResponse}},
)
async def reorder_task(
    project_id: int, task_id: int, data: ReorderRequest, user: CurrentUserDep, service: TaskServiceDep
) -> TaskRead:
    return await service.reorder_task(user.id, project_id, task_id, data)
