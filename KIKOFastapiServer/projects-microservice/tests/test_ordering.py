from dataclasses import dataclass

import pytest

from src.services.ordering import has_enough_gap, position_between, renumber


@dataclass
class Item:
    id: int
    position: float


@pytest.mark.parametrize(
    ("lower", "upper", "expected"),
    [
        (1000.0, 2000.0, 1500.0),  # pomiedzy
        (3000.0, None, 4000.0),  # na koniec
        (None, 1000.0, 0.0),  # na poczatek
        (None, -500.0, -1500.0),  # na poczatek, pozycje moga byc ujemne
        (None, None, 1000.0),  # pusta lista
    ],
)
def test_position_between(lower: float | None, upper: float | None, expected: float) -> None:
    assert position_between(lower, upper, step=1000.0) == expected


def test_has_enough_gap() -> None:
    assert has_enough_gap(1.0, 2.0, min_gap=0.5)
    assert not has_enough_gap(1.0, 1.0 + 1e-9, min_gap=1e-6)
    assert has_enough_gap(None, 1.0, min_gap=1e-6)


def test_renumber_keeps_order_and_spreads_positions() -> None:
    items = [Item(1, 0.1), Item(2, 0.10000001), Item(3, 0.10000002)]

    renumber(items, step=1000.0)

    assert [i.position for i in items] == [1000.0, 2000.0, 3000.0]
