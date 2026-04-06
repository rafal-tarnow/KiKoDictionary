from pydantic import BaseModel, ConfigDict
from typing import Dict, Optional

class HealthCheckResponse(BaseModel):
    status: str
    version: str
    uptime: Optional[float] = None
    components: Optional[Dict[str, str]] = None

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "status": "ok",
                "version": "1.0.0",
                "components": {
                    "database": "operational",
                    "redis": "down"
                }
            }
        }
    )