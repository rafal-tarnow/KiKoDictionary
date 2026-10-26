from abc import ABC, abstractmethod
from collections.abc import Sequence
from typing import Any, Generic, TypeVar

from sqlalchemy import ColumnElement, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.db.base import Base

ModelT = TypeVar("ModelT", bound=Base)


class PositionedRepository(ABC, Generic[ModelT]):
    """
    Wspolna warstwa dostepu do danych dla encji sortowanych recznie (Drag & Drop).

    "Scope" to grupa, w ramach ktorej liczy sie kolejnosc:
      - dla projektow: wszystkie projekty jednego usera (user_id),
      - dla zadan: wszystkie zadania jednego projektu (project_id).
    """

    model: type[ModelT]

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    @abstractmethod
    def _scope_filter(self, scope: Any) -> ColumnElement[bool]:
        """Warunek WHERE ograniczajacy zapytanie do jednej listy."""

    # --- Zapis ---
    def add(self, entity: ModelT) -> None:
        self.session.add(entity)

    async def delete(self, entity: ModelT) -> None:
        await self.session.delete(entity)

    async def flush(self) -> None:
        await self.session.flush()

    # --- Odczyt pozycji ---
    async def list_ordered(self, scope: Any) -> Sequence[ModelT]:
        query = (
            select(self.model)
            .where(self._scope_filter(scope))
            .order_by(self.model.position.asc(), self.model.id.asc())
        )
        result = await self.session.execute(query)
        return result.scalars().all()

    async def count(self, scope: Any) -> int:
        query = select(func.count()).select_from(self.model).where(self._scope_filter(scope))
        return (await self.session.execute(query)).scalar_one()

    async def max_position(self, scope: Any) -> float | None:
        query = select(func.max(self.model.position)).where(self._scope_filter(scope))
        return (await self.session.execute(query)).scalar_one_or_none()

    async def get_neighbour_after(self, scope: Any, position: float, exclude_id: int) -> ModelT | None:
        query = (
            select(self.model)
            .where(
                self._scope_filter(scope),
                self.model.position > position,
                self.model.id != exclude_id,
            )
            .order_by(self.model.position.asc(), self.model.id.asc())
            .limit(1)
        )
        return (await self.session.execute(query)).scalars().first()

    async def get_neighbour_before(self, scope: Any, position: float, exclude_id: int) -> ModelT | None:
        query = (
            select(self.model)
            .where(
                self._scope_filter(scope),
                self.model.position < position,
                self.model.id != exclude_id,
            )
            .order_by(self.model.position.desc(), self.model.id.desc())
            .limit(1)
        )
        return (await self.session.execute(query)).scalars().first()
