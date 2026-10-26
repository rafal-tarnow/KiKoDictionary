import enum
from datetime import date, datetime
from typing import TYPE_CHECKING

from sqlalchemy import Enum, ForeignKey, Index, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from src.db.base import Base
from src.db.models.mixins import PositionMixin, TimestampMixin
from src.db.types import UTCDateTime

if TYPE_CHECKING:
    from src.db.models.project import Project


class TaskPriority(str, enum.Enum):
    NONE = "none"
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class Task(TimestampMixin, PositionMixin, Base):
    __tablename__ = "tasks"

    id: Mapped[int] = mapped_column(primary_key=True)
    project_id: Mapped[int] = mapped_column(
        ForeignKey("projects.id", ondelete="CASCADE"), nullable=False
    )

    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(String(2000))

    is_completed: Mapped[bool] = mapped_column(default=False, nullable=False)
    completed_at: Mapped[datetime | None] = mapped_column(UTCDateTime())

    priority: Mapped[TaskPriority] = mapped_column(
        # native_enum=False -> VARCHAR + CHECK, przenosne miedzy SQLite/Postgres
        Enum(
            TaskPriority,
            native_enum=False,
            length=10,
            values_callable=lambda members: [m.value for m in members],
            validate_strings=True,
            name="task_priority",
        ),
        default=TaskPriority.NONE,
        nullable=False,
    )
    due_date: Mapped[date | None] = mapped_column()

    project: Mapped["Project"] = relationship(back_populates="tasks", lazy="raise")

    __table_args__ = (Index("ix_tasks_project_id_position", "project_id", "position"),)

    def __repr__(self) -> str:
        return f"<Task id={self.id} title={self.title!r}>"
