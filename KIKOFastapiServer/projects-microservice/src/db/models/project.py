from typing import TYPE_CHECKING

from sqlalchemy import Index, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from src.db.base import Base
from src.db.models.mixins import PositionMixin, TimestampMixin

if TYPE_CHECKING:
    from src.db.models.task import Task

DEFAULT_PROJECT_COLOR = "#673AB7"  # Colors.deepPurple - glowny kolor aplikacji


class Project(TimestampMixin, PositionMixin, Base):
    __tablename__ = "projects"

    id: Mapped[int] = mapped_column(primary_key=True)
    # UUID usera z auth-microservice (claim "sub" w JWT)
    user_id: Mapped[str] = mapped_column(String(36), nullable=False)

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str | None] = mapped_column(String(1000))
    color: Mapped[str] = mapped_column(String(7), default=DEFAULT_PROJECT_COLOR, nullable=False)

    # passive_deletes: usuwanie zadan robi baza (ON DELETE CASCADE),
    # ORM nie musi ich ladowac - wazne przy sesji asynchronicznej.
    tasks: Mapped[list["Task"]] = relationship(
        back_populates="project",
        cascade="all, delete-orphan",
        passive_deletes=True,
        lazy="raise",
    )

    __table_args__ = (
        # Najczestsze zapytanie: "projekty usera X posortowane po pozycji"
        Index("ix_projects_user_id_position", "user_id", "position"),
    )

    def __repr__(self) -> str:
        return f"<Project id={self.id} name={self.name!r}>"
