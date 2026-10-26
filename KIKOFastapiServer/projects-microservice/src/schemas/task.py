from datetime import date, datetime
from typing import ClassVar

from src.db.models import TaskPriority
from src.schemas.common import ApiModel, PartialUpdateModel, optional_text, required_text

TaskTitle = required_text(max_length=200)
TaskDescription = optional_text(max_length=2000)


class TaskCreate(ApiModel):
    title: TaskTitle
    description: TaskDescription = None
    priority: TaskPriority = TaskPriority.NONE
    due_date: date | None = None


class TaskUpdate(PartialUpdateModel):
    NULLABLE_FIELDS: ClassVar[frozenset[str]] = frozenset({"description", "due_date"})

    title: TaskTitle | None = None
    description: TaskDescription = None
    priority: TaskPriority | None = None
    due_date: date | None = None
    is_completed: bool | None = None


class TaskRead(ApiModel):
    id: int
    project_id: int
    title: str
    description: str | None
    priority: TaskPriority
    due_date: date | None
    is_completed: bool
    completed_at: datetime | None
    position: float
    created_at: datetime
    updated_at: datetime
