"""
Sortowanie "fractional indexing" dla list przeciaganych myszka / palcem.

Kazdy element ma `position: float`. Przeniesienie elementu zmienia TYLKO jego pozycje
(srednia z sasiadow), wiec jeden drag & drop = jeden UPDATE w bazie.
Gdy po wielu przesunieciach w to samo miejsce przerwa miedzy sasiadami staje sie
mikroskopijna (granica precyzji float), cala lista jest jednorazowo przenumerowana.
"""

from collections.abc import Sequence
from typing import Any, Generic, Protocol

from src.repositories.base import ModelT, PositionedRepository


class Positioned(Protocol):
    id: int
    position: float


def position_between(lower: float | None, upper: float | None, step: float) -> float:
    """Pozycja dla elementu wstawianego miedzy `lower` a `upper` (None = brak sasiada)."""
    if lower is not None and upper is not None:
        return (lower + upper) / 2.0
    if lower is not None:
        return lower + step
    if upper is not None:
        return upper - step
    return step


def has_enough_gap(lower: float | None, upper: float | None, min_gap: float) -> bool:
    return lower is None or upper is None or (upper - lower) >= min_gap


def renumber(items: Sequence[Positioned], step: float) -> None:
    """Rowne odstepy: step, 2*step, 3*step... (kolejnosc elementow bez zmian)."""
    for index, item in enumerate(items, start=1):
        item.position = index * step


class PositionManager(Generic[ModelT]):
    """Wylicza pozycje dla nowych i przesuwanych elementow w obrebie jednego "scope"."""

    def __init__(self, repository: PositionedRepository[ModelT], step: float, min_gap: float) -> None:
        self._repository = repository
        self._step = step
        self._min_gap = min_gap

    async def position_for_new_item(self, scope: Any) -> float:
        """Nowy element trafia na koniec listy."""
        max_position = await self._repository.max_position(scope)
        return position_between(max_position, None, self._step)

    async def move(
        self,
        item: ModelT,
        scope: Any,
        prev_item: ModelT | None,
        next_item: ModelT | None,
    ) -> None:
        """
        Ustawia `item` pomiedzy `prev_item` i `next_item`.

        Kotwica jest `prev_item` (a gdy go brak - `next_item`); drugiego sasiada
        dobieramy z bazy. Dzieki temu wynik jest poprawny nawet wtedy, gdy klient
        mial lekko nieaktualna liste (np. zmiany z innego urzadzenia).
        """
        if prev_item is None and next_item is None:
            return  # Lista jednoelementowa - nie ma czego przesuwac

        lower, upper = await self._resolve_bounds(item, scope, prev_item, next_item)

        if not has_enough_gap(lower, upper, self._min_gap):
            renumber(await self._repository.list_ordered(scope), self._step)
            # flush -> zapytania o sasiadow widza nowe pozycje; obiekty prev/next sa w tej
            # samej sesji (identity map), wiec ich atrybuty tez sa juz zaktualizowane
            await self._repository.flush()
            lower, upper = await self._resolve_bounds(item, scope, prev_item, next_item)

        item.position = position_between(lower, upper, self._step)

    async def _resolve_bounds(
        self,
        item: ModelT,
        scope: Any,
        prev_item: ModelT | None,
        next_item: ModelT | None,
    ) -> tuple[float | None, float | None]:
        if prev_item is not None:
            after = await self._repository.get_neighbour_after(scope, prev_item.position, exclude_id=item.id)
            return prev_item.position, after.position if after else None

        assert next_item is not None
        before = await self._repository.get_neighbour_before(scope, next_item.position, exclude_id=item.id)
        return before.position if before else None, next_item.position
