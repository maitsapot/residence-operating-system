import os

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

from app.core.settings import get_settings

settings = get_settings()
DATABASE_URL = settings.database_url or os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL environment variable is not set")


# Create engine (connection pool)
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
)


# Create session factory
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)


# Base class for all models
Base = declarative_base()


# Dependency (used in API routes later)
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
        
import app.models
