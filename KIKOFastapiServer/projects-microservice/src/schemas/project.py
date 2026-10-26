from datetime import datetime
from typing import Annotated, ClassVar

from pydantic import StringConstraints

from src.db.models import DEFAULT_PROJECT_COLOR
from src.schemas.common import ApiModel, PartialUpdateModel, optional_text, required_text

ProjectName = required_text(max_length=100)
ProjectDescription = optional_text(max_length=1000)
HexColor = Annotated[str, StringConstraints(pattern=r"^#[0-9A-Fa-f]{6}$", to_upper=True)]


class ProjectCreate(ApiModel):
    name: ProjectName
    description: ProjectDescription = None
    color: HexColor = DEFAULT_PROJECT_COLOR


class ProjectUpdate(PartialUpdateModel):
    NULLABLE_FIELDS: ClassVar[frozenset[str]] = frozenset({"description"})

    name: ProjectName | None = None
    description: ProjectDescription = None
    color: HexColor | None = None


class ProjectRead(ApiModel):
    id: int
    name: str
    description: str | None
    color: str
    position: float
    task_count: int = 0
    completed_task_count: int = 0
    created_at: datetime
    updated_at: datetime
