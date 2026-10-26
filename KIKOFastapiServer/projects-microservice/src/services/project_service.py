from sqlalchemy.ext.asyncio import AsyncSession

from src.core.config import Settings
from src.core.exceptions import InvalidReorderError, LimitExceededError, ProjectNotFoundError
from src.db.models import Project
from src.repositories import ProjectRepository, TaskStats
from src.schemas import ProjectCreate, ProjectRead, ProjectUpdate, ReorderRequest
from src.services.ordering import PositionManager


def to_project_read(project: Project, stats: TaskStats) -> ProjectRead:
    return ProjectRead.model_validate(project).model_copy(
        update={"task_count": stats.total, "completed_task_count": stats.completed}
    )


class ProjectService:
    """Logika biznesowa projektow. Kazda operacja jest ograniczona do projektow danego usera."""

    def __init__(self, session: AsyncSession, settings: Settings) -> None:
        self._session = session
        self._settings = settings
        self._projects = ProjectRepository(session)
        self._positions = PositionManager(self._projects, settings.POSITION_STEP, settings.POSITION_MIN_GAP)

    async def list_projects(self, user_id: str) -> list[ProjectRead]:
        rows = await self._projects.list_with_stats(user_id)
        return [to_project_read(project, stats) for project, stats in rows]

    async def get_project(self, user_id: str, project_id: int) -> ProjectRead:
        project = await self.get_owned_project(user_id, project_id)
        return to_project_read(project, await self._projects.get_stats(project.id))

    async def create_project(self, user_id: str, data: ProjectCreate) -> ProjectRead:
        if await self._projects.count(user_id) >= self._settings.MAX_PROJECTS_PER_USER:
            raise LimitExceededError(
                f"You can have at most {self._settings.MAX_PROJECTS_PER_USER} projects"
            )

        project = Project(
            user_id=user_id,
            **data.model_dump(),
            position=await self._positions.position_for_new_item(user_id),
        )
        self._projects.add(project)
        await self._session.commit()
        return to_project_read(project, TaskStats())

    async def update_project(self, user_id: str, project_id: int, data: ProjectUpdate) -> ProjectRead:
        project = await self.get_owned_project(user_id, project_id)
        for field, value in data.changes().items():
            setattr(project, field, value)
        await self._session.commit()
        return to_project_read(project, await self._projects.get_stats(project.id))

    async def delete_project(self, user_id: str, project_id: int) -> None:
        project = await self.get_owned_project(user_id, project_id)
        # Zadania usuwa baza (ON DELETE CASCADE)
        await self._projects.delete(project)
        await self._session.commit()

    async def reorder_project(self, user_id: str, project_id: int, data: ReorderRequest) -> ProjectRead:
        project = await self.get_owned_project(user_id, project_id)
        if project_id in (data.prev_id, data.next_id):
            raise InvalidReorderError("Project cannot be its own neighbour")

        prev_project = await self._get_neighbour(user_id, data.prev_id)
        next_project = await self._get_neighbour(user_id, data.next_id)

        await self._positions.move(project, user_id, prev_project, next_project)
        await self._session.commit()
        return to_project_read(project, await self._projects.get_stats(project.id))

    async def get_owned_project(self, user_id: str, project_id: int) -> Project:
        project = await self._projects.get_for_user(user_id, project_id)
        if project is None:
            # 404 (a nie 403) - nie zdradzamy, ze projekt o takim ID istnieje u kogos innego
            raise ProjectNotFoundError()
        return project

    async def _get_neighbour(self, user_id: str, project_id: int | None) -> Project | None:
        if project_id is None:
            return None
        neighbour = await self._projects.get_for_user(user_id, project_id)
        if neighbour is None:
            raise InvalidReorderError(f"Neighbour project {project_id} not found")
        return neighbour
