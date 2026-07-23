from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.sql import func
from src.db.models import Task
from src.schemas.task import TaskCreate, TaskUpdate
from src.core.config import settings
from fastapi import HTTPException

class TaskRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_user_tasks(self, user_id: str):
        # Pobieramy zadania posortowane po pozycji (rosnąco)
        query = select(Task).filter(Task.user_id == user_id).order_by(Task.position.asc())
        result = await self.db.execute(query)
        return result.scalars().all()

    async def create_task(self, user_id: str, task_in: TaskCreate) -> Task:
        # Znajdź najwyższą pozycję obecnie w bazie dla tego usera
        query = select(func.max(Task.position)).filter(Task.user_id == user_id)
        result = await self.db.execute(query)
        max_pos = result.scalar()
        
        # Jeśli nie ma zadań, startujemy od 1000. W przeciwnym razie dodajemy 1000 do najwyższej.
        new_position = settings.POSITION_STEP if max_pos is None else max_pos + settings.POSITION_STEP

        db_task = Task(
            user_id=user_id,
            content=task_in.content,
            position=new_position
        )
        self.db.add(db_task)
        await self.db.commit()
        await self.db.refresh(db_task)
        return db_task

    async def update_task(self, user_id: str, task_id: int, task_in: TaskUpdate) -> Task:
        task = await self.get_task_by_id(user_id, task_id)
        
        if task_in.content is not None:
            task.content = task_in.content
        if task_in.is_completed is not None:
            task.is_completed = task_in.is_completed
            
        await self.db.commit()
        await self.db.refresh(task)
        return task

    async def delete_task(self, user_id: str, task_id: int):
        task = await self.get_task_by_id(user_id, task_id)
        await self.db.delete(task)
        await self.db.commit()

    async def reorder_task(self, user_id: str, task_id: int, prev_id: int | None, next_id: int | None) -> Task:
        """
        Główny algorytm obliczania nowej pozycji.
        """
        task_to_move = await self.get_task_by_id(user_id, task_id)
        
        prev_task = await self.get_task_by_id(user_id, prev_id) if prev_id else None
        next_task = await self.get_task_by_id(user_id, next_id) if next_id else None

        if prev_task and next_task:
            # Wstawienie pomiędzy dwa istniejące zadania (wyciągamy średnią)
            new_pos = (prev_task.position + next_task.position) / 2.0
        elif prev_task and not next_task:
            # Przeniesienie na sam dół listy
            new_pos = prev_task.position + settings.POSITION_STEP
        elif not prev_task and next_task:
            # Przeniesienie na samą górę listy
            new_pos = next_task.position / 2.0  # Średnia między 0 a pierwszym elementem
        else:
            # Jeśli front wyśle oba jako None (lista miała 1 element), nic nie robimy
            new_pos = task_to_move.position

        task_to_move.position = new_pos
        await self.db.commit()
        await self.db.refresh(task_to_move)
        return task_to_move

    async def get_task_by_id(self, user_id: str, task_id: int) -> Task:
        query = select(Task).filter(Task.id == task_id, Task.user_id == user_id)
        result = await self.db.execute(query)
        task = result.scalars().first()
        if not task:
            raise HTTPException(status_code=404, detail="Task not found")
        return task