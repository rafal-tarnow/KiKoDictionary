from typing import Annotated, Any, ClassVar, Self

from pydantic import AfterValidator, BaseModel, ConfigDict, Field, StringConstraints, model_validator


def _blank_to_none(value: str | None) -> str | None:
    return value or None


def required_text(max_length: int) -> Any:
    """Tekst wymagany: obciete spacje, min. 1 znak."""
    return Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=max_length)]


def optional_text(max_length: int) -> Any:
    """Tekst opcjonalny: pusty string / same spacje zapisujemy jako NULL."""
    return Annotated[
        Annotated[str, StringConstraints(strip_whitespace=True, max_length=max_length)] | None,
        AfterValidator(_blank_to_none),
    ]


class ApiModel(BaseModel):
    model_config = ConfigDict(from_attributes=True, extra="forbid")


class PartialUpdateModel(ApiModel):
    """
    Baza dla PATCH. Pole pominiete = "nie zmieniaj". Pole wyslane jako null:
      - dla pol z NULLABLE_FIELDS = "wyczysc wartosc",
      - dla pozostalych = blad walidacji (np. nie mozna wyczyscic nazwy projektu).
    """

    NULLABLE_FIELDS: ClassVar[frozenset[str]] = frozenset()

    @model_validator(mode="after")
    def _reject_null_for_required_fields(self) -> Self:
        for field_name in self.model_fields_set - self.NULLABLE_FIELDS:
            if getattr(self, field_name) is None:
                raise ValueError(f"Field '{field_name}' cannot be null")
        return self

    def changes(self) -> dict:
        """Tylko pola faktycznie wyslane przez klienta."""
        return self.model_dump(exclude_unset=True)


class ReorderRequest(ApiModel):
    """
    Wynik "upuszczenia" elementu na liscie. Frontend wysyla ID sasiadow w nowym miejscu:
      - prev_id = element bezposrednio NAD upuszczonym (None -> poczatek listy),
      - next_id = element bezposrednio POD upuszczonym (None -> koniec listy).
    """

    prev_id: int | None = Field(default=None, description="ID elementu nad nowa pozycja")
    next_id: int | None = Field(default=None, description="ID elementu pod nowa pozycja")

    @model_validator(mode="after")
    def _neighbours_must_differ(self) -> Self:
        if self.prev_id is not None and self.prev_id == self.next_id:
            raise ValueError("prev_id and next_id must be different")
        return self


class ErrorResponse(BaseModel):
    detail: str
    error_code: str
