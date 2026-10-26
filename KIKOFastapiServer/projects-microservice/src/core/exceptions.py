from fastapi import status


class AppError(Exception):
    """
    Bazowy wyjatek domenowy. Warstwa serwisow rzuca te wyjatki,
    a handler w `src.core.exception_handlers` zamienia je na odpowiedz HTTP.
    Dzieki temu serwisy nie wiedza nic o FastAPI/HTTP.
    """

    status_code: int = status.HTTP_400_BAD_REQUEST
    error_code: str = "APP_ERROR"
    detail: str = "Application error."

    def __init__(self, detail: str | None = None) -> None:
        if detail is not None:
            self.detail = detail
        super().__init__(self.detail)


class AuthenticationError(AppError):
    status_code = status.HTTP_401_UNAUTHORIZED
    error_code = "NOT_AUTHENTICATED"
    detail = "Could not validate credentials"


class NotFoundError(AppError):
    status_code = status.HTTP_404_NOT_FOUND
    error_code = "NOT_FOUND"
    detail = "Resource not found"


class ProjectNotFoundError(NotFoundError):
    error_code = "PROJECT_NOT_FOUND"
    detail = "Project not found"


class TaskNotFoundError(NotFoundError):
    error_code = "TASK_NOT_FOUND"
    detail = "Task not found"


class InvalidReorderError(AppError):
    status_code = status.HTTP_400_BAD_REQUEST
    error_code = "INVALID_REORDER"
    detail = "Invalid reorder request"


class LimitExceededError(AppError):
    status_code = status.HTTP_409_CONFLICT
    error_code = "LIMIT_EXCEEDED"
    detail = "Limit exceeded"
