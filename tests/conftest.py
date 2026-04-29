import os

import pytest
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

load_dotenv()

os.environ.setdefault(
    "DATABASE_URL",
    os.getenv("TEST_DATABASE_URL", "postgresql+psycopg2://user:pass@127.0.0.1:5432/db")
)

from app.core.database import Base
import app.models  # noqa: F401


def _drop_metadata_tables_cascade(engine):
    table_names = list(Base.metadata.tables.keys())
    if not table_names:
        return

    quoted_names = ", ".join(f'"{table_name}"' for table_name in table_names)
    with engine.begin() as conn:
        conn.execute(text(f"DROP TABLE IF EXISTS {quoted_names} CASCADE"))


@pytest.fixture(scope="session")
def test_engine():
    database_url = os.getenv("TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("TEST_DATABASE_URL is required for database integration tests")

    if (
        database_url == os.getenv("DATABASE_URL")
        and os.getenv("ALLOW_RESET_TEST_DB") != "1"
    ):
        pytest.skip(
            "TEST_DATABASE_URL matches DATABASE_URL; set a separate test database "
            "or ALLOW_RESET_TEST_DB=1 to allow schema reset"
        )

    engine = create_engine(database_url)

    with engine.begin() as conn:
        conn.execute(text("CREATE EXTENSION IF NOT EXISTS pgcrypto"))
        conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))

    yield engine

    _drop_metadata_tables_cascade(engine)
    engine.dispose()


@pytest.fixture()
def db_session(test_engine):
    _drop_metadata_tables_cascade(test_engine)
    Base.metadata.create_all(bind=test_engine)

    SessionLocal = sessionmaker(
        autocommit=False,
        autoflush=False,
        bind=test_engine,
    )
    session = SessionLocal()

    try:
        yield session
    finally:
        session.rollback()
        session.close()
