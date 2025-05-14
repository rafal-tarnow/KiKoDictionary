from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# URL bazy danych (SQLite dla prostoty, można zmienić na PostgreSQL)
DATABASE_URL = "sqlite:///./sentences.db"
# Przykład dla PostgreSQL:
# DATABASE_URL = "postgresql://user:password@localhost:5432/dbname"

# Tworzenie silnika SQLAlchemy
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False}  # Tylko dla SQLite
)

# Sesja do interakcji z bazą danych
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Baza dla modeli SQLAlchemy
Base = declarative_base()

# Dependency do uzyskania sesji bazy danych
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()