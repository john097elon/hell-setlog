"""SQLAlchemy database setup for Hell Setlog — SQLite at ./data/hellsetlog.db."""
import os

from sqlalchemy import create_engine, text
from sqlalchemy.orm import declarative_base, sessionmaker

# Ensure the data directory exists
DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
os.makedirs(DATA_DIR, exist_ok=True)

DATABASE_URL = f"sqlite:///{os.path.join(DATA_DIR, 'hellsetlog.db')}"

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False},  # Required for SQLite + FastAPI
    echo=False,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    """FastAPI dependency that provides a database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def _sqlite_columns(conn, table_name: str) -> set[str]:
    rows = conn.execute(text(f"PRAGMA table_info({table_name})")).fetchall()
    return {row[1] for row in rows}


def _add_column_if_missing(conn, table_name: str, column_name: str, ddl: str) -> None:
    if column_name not in _sqlite_columns(conn, table_name):
        conn.execute(text(f"ALTER TABLE {table_name} ADD COLUMN {ddl}"))


def migrate_sqlite() -> None:
    """Idempotent SQLite migration for columns added after create_all-only DBs."""
    with engine.begin() as conn:
        existing_tables = {row[0] for row in conn.execute(text("SELECT name FROM sqlite_master WHERE type='table'"))}
        if "users" in existing_tables:
            _add_column_if_missing(conn, "users", "workout_tags", "workout_tags VARCHAR(500) DEFAULT '[]'")
        if "parties" in existing_tables:
            _add_column_if_missing(conn, "parties", "match_type", "match_type VARCHAR(20) NOT NULL DEFAULT 'manual'")
            _add_column_if_missing(conn, "parties", "max_members", "max_members INTEGER NOT NULL DEFAULT 4")
            _add_column_if_missing(conn, "parties", "is_open", "is_open BOOLEAN NOT NULL DEFAULT 1")
            _add_column_if_missing(conn, "parties", "last_matched_at", "last_matched_at DATETIME")
        if "party_members" in existing_tables:
            _add_column_if_missing(conn, "party_members", "role", "role VARCHAR(20) NOT NULL DEFAULT 'member'")
            _add_column_if_missing(conn, "party_members", "status", "status VARCHAR(20) NOT NULL DEFAULT 'active'")
            _add_column_if_missing(conn, "party_members", "left_at", "left_at DATETIME")
            conn.execute(text("UPDATE party_members SET role = 'owner' WHERE id IN (SELECT pm.id FROM party_members pm JOIN parties p ON p.id = pm.party_id WHERE p.owner_id = pm.user_id)"))


def init_db():
    """Create all tables and run lightweight SQLite migrations. Call on startup."""
    # Import models so they register with Base.metadata
    import models  # noqa: F401
    Base.metadata.create_all(bind=engine)
    migrate_sqlite()
