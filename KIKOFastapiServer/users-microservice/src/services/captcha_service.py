import httpx
from fastapi import HTTPException, status
from src.core.config import settings

class CaptchaService:
    def __init__(self):
        self.base_url = f"{settings.CAPTCHA_SERVICE_URL}/api/v1/captcha"

    async def verify(self, captcha_id: str, answer: str) -> bool:
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{self.base_url}/verify",
                    json={"id": captcha_id, "answer": answer}
                )
                response.raise_for_status()
                data = response.json()
                return data.get("is_valid", False)
            except httpx.RequestError:
                raise HTTPException(
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                    detail="Captcha service is currently unavailable."
                )
            except Exception:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="An error occurred while verifying captcha."
                )