from pydantic import BaseModel
from typing import Dict, Optional

class HealthCheckResponse(BaseModel):
    status: str
    version: str
    uptime: Optional[float] = None
    components: Optional[Dict[str, str]] = None

    class Config:
        json_schema_extra = {
            "example": {
                "status": "ok",
                "version": "1.0.0",
                "components": {
                    "database": "operational",
                    "redis": "down"
                }
            }
        }