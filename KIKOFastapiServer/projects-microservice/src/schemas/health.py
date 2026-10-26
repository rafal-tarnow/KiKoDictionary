from pydantic import BaseModel


class HealthCheckResponse(BaseModel):
    status: str
    version: str
    components: dict[str, str] | None = None
