"""SQLAlchemy engine and request-scoped session management."""

from pathlib import Path
from typing import Any

from sqlalchemy import create_engine
from sqlalchemy.engine import Engine, make_url
from sqlalchemy.orm import declarative_base, sessionmaker

from settings import Settings, get_settings


def _ensure_sqlite_directory(database_url: str) -> None:
    url = make_url(database_url)
    if not url.database or url.database == ":memory:":
        return
    database_path = Path(url.database)
    if not database_path.is_absolute():
        database_path = Path.cwd() / database_path
    database_path.parent.mkdir(parents=True, exist_ok=True)


def create_database_engine(settings: Settings) -> Engine:
    """Create an engine without connecting or mutating schema state."""

    engine_options: dict[str, Any] = {"pool_pre_ping": True}
    if settings.database_url.startswith("sqlite"):
        _ensure_sqlite_directory(settings.database_url)
        engine_options["connect_args"] = {"check_same_thread": False}
    else:
        engine_options.update(pool_size=5, max_overflow=10, pool_recycle=1800)
    return create_engine(settings.database_url, **engine_options)


settings = get_settings()
engine = create_database_engine(settings)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    """Provide one SQLAlchemy session per request."""

    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
