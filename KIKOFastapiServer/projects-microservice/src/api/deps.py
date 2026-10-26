from typing import Annotated

from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.config import Settings, get_settings
from src.core.exceptions import AuthenticationError
from src.core.security import CurrentUser, decode_access_token
from src.db.session import get_db_session
from src.services import ProjectService, TaskService

# auto_error=False -> brak tokena obslugujemy sami, zeby zwrocic spojny format bledu
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=get_settings().AUTH_TOKEN_URL, auto_error=False)

SessionDep = Annotated[AsyncSession, Depends(get_db_session)]
SettingsDep = Annotated[Settings, Depends(get_settings)]


def get_current_user(token: Annotated[str | None, Depends(oauth2_scheme)]) -> CurrentUser:
    if not token:
        raise AuthenticationError("Not authenticated")
    return decode_access_token(token)


CurrentUserDep = Annotated[CurrentUser, Depends(get_current_user)]


def get_project_service(session: SessionDep, settings: SettingsDep) -> ProjectService:
    return ProjectService(session, settings)


def get_task_service(session: SessionDep, settings: SettingsDep) -> TaskService:
    return TaskService(session, settings)


ProjectServiceDep = Annotated[ProjectService, Depends(get_project_service)]
TaskServiceDep = Annotated[TaskService, Depends(get_task_service)]
