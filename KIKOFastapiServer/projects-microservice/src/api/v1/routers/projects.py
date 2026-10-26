from fastapi import APIRouter, status

from src.api.deps import CurrentUserDep, ProjectServiceDep
from src.schemas import ErrorResponse, ProjectCreate, ProjectRead, ProjectUpdate, ReorderRequest

router = APIRouter(
    prefix="/projects",
    tags=["Projects"],
    responses={
        status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponse},
        status.HTTP_404_NOT_FOUND: {"model": ErrorResponse},
    },
)


@router.get("", response_model=list[ProjectRead], summary="List my projects (in display order)")
async def list_projects(user: CurrentUserDep, service: ProjectServiceDep) -> list[ProjectRead]:
    return await service.list_projects(user.id)


@router.post(
    "",
    response_model=ProjectRead,
    status_code=status.HTTP_201_CREATED,
    summary="Create a project (appended to the end of the list)",
    responses={status.HTTP_409_CONFLICT: {"model": ErrorResponse}},
)
async def create_project(data: ProjectCreate, user: CurrentUserDep, service: ProjectServiceDep) -> ProjectRead:
    return await service.create_project(user.id, data)


@router.get("/{project_id}", response_model=ProjectRead, summary="Get a project")
async def get_project(project_id: int, user: CurrentUserDep, service: ProjectServiceDep) -> ProjectRead:
    return await service.get_project(user.id, project_id)


@router.patch("/{project_id}", response_model=ProjectRead, summary="Partially update a project")
async def update_project(
    project_id: int, data: ProjectUpdate, user: CurrentUserDep, service: ProjectServiceDep
) -> ProjectRead:
    return await service.update_project(user.id, project_id, data)


@router.delete(
    "/{project_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a project together with all its tasks",
)
async def delete_project(project_id: int, user: CurrentUserDep, service: ProjectServiceDep) -> None:
    await service.delete_project(user.id, project_id)


@router.post(
    "/{project_id}/reorder",
    response_model=ProjectRead,
    summary="Move a project between two neighbours (drag & drop)",
    responses={status.HTTP_400_BAD_REQUEST: {"model": ErrorResponse}},
)
async def reorder_project(
    project_id: int, data: ReorderRequest, user: CurrentUserDep, service: ProjectServiceDep
) -> ProjectRead:
    return await service.reorder_project(user.id, project_id, data)
