from sqlalchemy import ColumnElement, select

from src.db.models import Task
from src.repositories.base import PositionedRepository


class TaskRepository(PositionedRepository[Task]):
    model = Task

    def _scope_filter(self, scope: int) -> ColumnElement[bool]:
        return Task.project_id == scope

    async def get_in_project(self, project_id: int, task_id: int) -> Task | None:
        query = select(Task).where(Task.id == task_id, Task.project_id == project_id)
        return (await self.session.execute(query)).scalars().first()
