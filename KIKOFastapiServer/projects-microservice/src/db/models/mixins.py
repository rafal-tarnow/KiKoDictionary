from datetime import datetime

from sqlalchemy.orm import Mapped, mapped_column

from src.db.types import UTCDateTime, utc_now


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(UTCDateTime(), default=utc_now, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        UTCDateTime(), default=utc_now, onupdate=utc_now, nullable=False
    )


class PositionMixin:
    # Float pozwala wstawiac element "pomiedzy" dwa inne bez przenumerowania calej listy
    position: Mapped[float] = mapped_column(nullable=False)
