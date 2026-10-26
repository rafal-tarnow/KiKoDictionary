from sqlalchemy.ext.asyncio import AsyncSession

from src.core.config import Settings
from src.core.exceptions import InvalidReorderError, LimitExceededError, TaskNotFoundError
from src.db.models import Task
from src.db.types import utc_now
from src.repositories import TaskRepository
from src.schemas import ReorderRequest, TaskCreate, TaskRead, TaskUpdate
from src.services.ordering import PositionManager
from src.services.project_service import ProjectService


class TaskService:
    """
    Logika biznesowa zadan. Kazda operacja najpierw sprawdza, czy projekt nalezy
    do usera - zadanie "dziedziczy" wlasciciela po projekcie.
    """

    def __init__(self, session: AsyncSession, settings: Settings) -> None:
        self._session = session
        self._settings = settings
        self._projects = ProjectService(session, settings)
        self._tasks = TaskRepository(session)
        self._positions = PositionManager(self._tasks, settings.POSITION_STEP, settings.POSITION_MIN_GAP)

    async def list_tasks(self, user_id: str, project_id: int) -> list[TaskRead]:
        project = await self._projects.get_owned_project(user_id, project_id)
        tasks = await self._tasks.list_ordered(project.id)
        return [TaskRead.model_validate(task) for task in tasks]

    async def get_task(self, user_id: str, project_id: int, task_id: int) -> TaskRead:
        task = await self._get_owned_task(user_id, project_id, task_id)
        return TaskRead.model_validate(task)

    async def create_task(self, user_id: str, project_id: int, data: TaskCreate) -> TaskRead:
        project = await self._projects.get_owned_project(user_id, project_id)
        if await self._tasks.count(project.id) >= self._settings.MAX_TASKS_PER_PROJECT:
            raise LimitExceededError(
                f"A project can have at most {self._settings.MAX_TASKS_PER_PROJECT} tasks"
            )

        task = Task(
            project_id=project.id,
            **data.model_dump(),
            position=await self._positions.position_for_new_item(project.id),
        )
        self._tasks.add(task)
        await self._session.commit()
        return TaskRead.model_validate(task)

    async def update_task(self, user_id: str, project_id: int, task_id: int, data: TaskUpdate) -> TaskRead:
        task = await self._get_owned_task(user_id, project_id, task_id)
        changes = data.changes()

        is_completed = changes.pop("is_completed", None)
        if is_completed is not None and is_completed != task.is_completed:
            task.is_completed = is_completed
            task.completed_at = utc_now() if is_completed else None

        for field, value in changes.items():
            setattr(task, field, value)

        await self._session.commit()
        return TaskRead.model_validate(task)

    async def delete_task(self, user_id: str, project_id: int, task_id: int) -> None:
        task = await self._get_owned_task(user_id, project_id, task_id)
        await self._tasks.delete(task)
        await self._session.commit()

    async def reorder_task(self, user_id: str, project_id: int, task_id: int, data: ReorderRequest) -> TaskRead:
        task = await self._get_owned_task(user_id, project_id, task_id)
        if task_id in (data.prev_id, data.next_id):
            raise InvalidReorderError("Task cannot be its own neighbour")

        prev_task = await self._get_neighbour(project_id, data.prev_id)
        next_task = await self._get_neighbour(project_id, data.next_id)

        await self._positions.move(task, project_id, prev_task, next_task)
        await self._session.commit()
        return TaskRead.model_validate(task)

    async def _get_owned_task(self, user_id: str, project_id: int, task_id: int) -> Task:
        project = await self._projects.get_owned_project(user_id, project_id)
        task = await self._tasks.get_in_project(project.id, task_id)
        if task is None:
            raise TaskNotFoundError()
        return task

    async def _get_neighbour(self, project_id: int, task_id: int | None) -> Task | None:
        if task_id is None:
            return None
        neighbour = await self._tasks.get_in_project(project_id, task_id)
        if neighbour is None:
            raise InvalidReorderError(f"Neighbour task {task_id} not found in this project")
        return neighbour
