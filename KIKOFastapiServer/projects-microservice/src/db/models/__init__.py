# Import wszystkich modeli w jednym miejscu - Alembic (migrations/env.py)
# i testy importuja ten pakiet, zeby Base.metadata znal wszystkie tabele.
from src.db.models.project import DEFAULT_PROJECT_COLOR, Project
from src.db.models.task import Task, TaskPriority

__all__ = ["DEFAULT_PROJECT_COLOR", "Project", "Task", "TaskPriority"]
