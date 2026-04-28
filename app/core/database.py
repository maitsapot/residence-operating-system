from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# IMPORTANT: password has "$" → encoded as %24
DATABASE_URL = "postgresql+psycopg2://tebogo:Karu8082%24@127.0.0.1:5432/ros_mobile"


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