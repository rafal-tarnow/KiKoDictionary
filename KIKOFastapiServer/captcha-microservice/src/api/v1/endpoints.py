from fastapi import APIRouter, Depends, HTTPException
from src.schemas.captcha import CaptchaResponse, CaptchaVerifyRequest, CaptchaVerifyResponse
from src.database.repository import CaptchaRepository
from src.core.captcha_generator import CaptchaGenerator
from src.dependencies import get_captcha_repository, get_captcha_generator

router = APIRouter()

# @router.get("/captcha", response_model=CaptchaResponse)
# async def generate_captcha(
#     repo: CaptchaRepository = Depends(get_captcha_repository),
#     generator: CaptchaGenerator = Depends(get_captcha_generator)
# ):
#     text, image = generator.generate_captcha()
#     captcha = repo.create_captcha(text)
#     return CaptchaResponse(
#         id=captcha.id,
#         text=text,
#         image=image,
#         created_at=captcha.created_at
#     )


# @router.get("/captcha/{captcha_id}", response_model=CaptchaResponse)
# async def get_captcha(
#     captcha_id: int,
#     repo: CaptchaRepository = Depends(get_captcha_repository)
# ):
#     captcha = repo.get_captcha(captcha_id)
#     if not captcha:
#         raise HTTPException(status_code=404, detail="Captcha not found")
#     return CaptchaResponse(
#         id=captcha.id,
#         image="",  # Image is not stored, would need to be regenerated or cached
#         created_at=captcha.created_at
#     )


# @router.post("/captcha/verify", response_model=CaptchaVerifyResponse)
# async def verify_captcha(
#     request: CaptchaVerifyRequest,
#     repo: CaptchaRepository = Depends(get_captcha_repository)
# ):
#     captcha = repo.get_captcha(request.id)
#     if not captcha:
#         raise HTTPException(status_code=404, detail="Captcha not found")
    
#     is_valid = captcha.text == request.text
#     return CaptchaVerifyResponse(is_valid=is_valid)

###############################################################################


import uuid
from src.core.config import settings
from src.schemas.captcha import CaptchaChallengeResponse

@router.get("/captcha", response_model=CaptchaChallengeResponse)
async def generate_captcha(
    repo: CaptchaRepository = Depends(get_captcha_repository), # Rozważ repozytorium cache
    generator: CaptchaGenerator = Depends(get_captcha_generator)
):
    text_solution, image_data_url = generator.generate_captcha()
    captcha_id = uuid.uuid4() # Generuj UUID
    
    # Zapisz parę (captcha_id, text_solution) w repozytorium/cache z TTL
    # repo.create_captcha(str(captcha_id), text_solution, ttl_seconds=settings.CACHE_TTL) 
    # Metoda create_captcha musi być dostosowana do przyjmowania ID i TTL
    # Dla uproszczenia, jeśli repo to cache (np. Redis), to:
    # await cache.set(f"captcha:{captcha_id}", text_solution, expire=settings.CACHE_TTL)

    # ---- PRZYKŁAD Z REPOZYTORIUM SQL (wymaga modyfikacji repo) ----
    repo.create_captcha_entry(str(captcha_id), text_solution) # Zakładamy, że repo zajmuje się TTL w get_captcha_entry

    return CaptchaChallengeResponse(
        id=captcha_id,
        image=image_data_url
    )


@router.post("/captcha/verify", response_model=CaptchaVerifyResponse)
async def verify_captcha(
    request: CaptchaVerifyRequest,
    repo: CaptchaRepository = Depends(get_captcha_repository) # Rozważ repozytorium cache
):
    # Pobierz text_solution dla request.id z repozytorium/cache
    # Jeśli używasz cache:
    # text_solution = await cache.get(f"captcha:{request.id}")
    # if text_solution:
    #     await cache.delete(f"captcha:{request.id}") # Usuń po pierwszej próbie

    # ---- PRZYKŁAD Z REPOZYTORIUM SQL (wymaga modyfikacji repo) ----
    captcha_entry = repo.get_valid_captcha_entry(str(request.id), ttl_seconds=settings.CACHE_TTL)
    
    is_valid = False
    if captcha_entry:
        # Porównanie case-insensitive
        is_valid = captcha_entry.text.lower() == request.answer.lower()
        repo.delete_captcha_entry(str(request.id)) # Usuń po weryfikacji
    
    # Nawet jeśli captcha_entry to None (nie znaleziono lub wygasło), is_valid pozostanie False
    return CaptchaVerifyResponse(is_valid=is_valid)