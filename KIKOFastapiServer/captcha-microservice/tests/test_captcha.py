import uuid
from datetime import datetime, timedelta, timezone

from src.core.config import settings
from src.database.models import Captcha

CAPTCHA_URL = "/api/v1/captcha"
VERIFY_URL = "/api/v1/captcha/verify"


def _solution(db_session_factory, captcha_id: str) -> str:
    with db_session_factory() as db:
        return db.get(Captcha, captcha_id).text


def test_generate_captcha_returns_image_without_solution(client, db_session_factory):
    response = client.get(CAPTCHA_URL)

    assert response.status_code == 200
    data = response.json()
    assert set(data) == {"id", "image"}  # rozwiązanie nie może wyciec do klienta
    assert data["image"].startswith("data:image/png;base64,")
    uuid.UUID(data["id"])

    solution = _solution(db_session_factory, data["id"])
    assert len(solution) == settings.CAPTCHA_LENGTH


def test_verify_correct_answer_is_case_insensitive(client, db_session_factory):
    captcha_id = client.get(CAPTCHA_URL).json()["id"]
    answer = _solution(db_session_factory, captcha_id).swapcase()

    response = client.post(VERIFY_URL, json={"id": captcha_id, "answer": answer})

    assert response.status_code == 200
    assert response.json() == {"is_valid": True}


def test_captcha_can_be_used_only_once(client, db_session_factory):
    captcha_id = client.get(CAPTCHA_URL).json()["id"]
    answer = _solution(db_session_factory, captcha_id)

    first = client.post(VERIFY_URL, json={"id": captcha_id, "answer": answer})
    second = client.post(VERIFY_URL, json={"id": captcha_id, "answer": answer})

    assert first.json()["is_valid"] is True
    assert second.json()["is_valid"] is False


def test_wrong_answer_is_rejected_and_captcha_invalidated(client, db_session_factory):
    captcha_id = client.get(CAPTCHA_URL).json()["id"]
    answer = _solution(db_session_factory, captcha_id)

    wrong = client.post(VERIFY_URL, json={"id": captcha_id, "answer": answer + "x"})
    retry = client.post(VERIFY_URL, json={"id": captcha_id, "answer": answer})

    assert wrong.json()["is_valid"] is False
    assert retry.json()["is_valid"] is False  # brak drugiej próby na tym samym obrazku


def test_unknown_captcha_is_invalid(client):
    response = client.post(VERIFY_URL, json={"id": str(uuid.uuid4()), "answer": "abc"})

    assert response.status_code == 200
    assert response.json() == {"is_valid": False}


def test_expired_captcha_is_invalid_and_removed(client, db_session_factory):
    captcha_id = str(uuid.uuid4())
    expired_at = datetime.now(timezone.utc) - timedelta(seconds=settings.CACHE_TTL + 1)
    with db_session_factory() as db:
        db.add(Captcha(id=captcha_id, text="ABC123", created_at=expired_at))
        db.commit()

    response = client.post(VERIFY_URL, json={"id": captcha_id, "answer": "ABC123"})

    assert response.json() == {"is_valid": False}
    with db_session_factory() as db:
        assert db.get(Captcha, captcha_id) is None


def test_verify_rejects_invalid_payload(client):
    response = client.post(VERIFY_URL, json={"id": "not-a-uuid", "answer": "abc"})

    assert response.status_code == 422


def test_health_live(client):
    response = client.get("/health/live")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"
