from collections.abc import Sequence
from dataclasses import dataclass

from sqlalchemy import ColumnElement, case, func, select

from src.db.models import Project, Task
from src.repositories.base import PositionedRepository


@dataclass(frozen=True, slots=True)
class TaskStats:
    total: int = 0
    completed: int = 0


class ProjectRepository(PositionedRepository[Project]):
    model = Project

    def _scope_filter(self, scope: str) -> ColumnElement[bool]:
        return Project.user_id == scope

    async def get_for_user(self, user_id: str, project_id: int) -> Project | None:
        query = select(Project).where(Project.id == project_id, Project.user_id == user_id)
        return (await self.session.execute(query)).scalars().first()

    async def list_with_stats(self, user_id: str) -> Sequence[tuple[Project, TaskStats]]:
        """Jedno zapytanie (LEFT JOIN + GROUP BY) zamiast N+1 zapytan o liczniki zadan."""
        total = func.count(Task.id)
        completed = func.coalesce(func.sum(case((Task.is_completed.is_(True), 1), else_=0)), 0)
        query = (
            select(Project, total, completed)
            .outerjoin(Task, Task.project_id == Project.id)
            .where(Project.user_id == user_id)
            .group_by(Project.id)
            .order_by(Project.position.asc(), Project.id.asc())
        )
        rows = (await self.session.execute(query)).all()
        return [(project, TaskStats(total=t, completed=c)) for project, t, c in rows]

    async def get_stats(self, project_id: int) -> TaskStats:
        query = select(
            func.count(Task.id),
            func.coalesce(func.sum(case((Task.is_completed.is_(True), 1), else_=0)), 0),
        ).where(Task.project_id == project_id)
        total, completed = (await self.session.execute(query)).one()
        return TaskStats(total=total, completed=completed)
