import importlib
import importlib.util
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

import pytest
from alembic import command
from sqlalchemy import create_engine, text
from sqlalchemy.exc import IntegrityError

from database import Base
from tests.test_migrations import alembic_config

NOW = datetime(2026, 7, 15, tzinfo=timezone.utc)
TABLE_ORDER = (
    "users",
    "characters",
    "parties",
    "party_members",
    "workouts",
    "setlogs",
    "body_stats",
    "reactions",
)


def migration_module():
    module_name = "scripts.migrate_sqlite_to_postgres"
    assert importlib.util.find_spec(module_name) is not None, "migration module must exist"
    return importlib.import_module(module_name)


def shared_memory_url(name: str) -> str:
    return f"sqlite:///file:{name}?mode=memory&cache=shared&uri=true"


def prepare_source(url: str, orphan_reaction: bool = False):
    engine = create_engine(url)
    Base.metadata.create_all(engine)
    with engine.begin() as connection:
        connection.execute(
            text(
                "INSERT INTO users "
                "(id, username, email, password_hash, character_id, workout_tags, created_at) "
                "VALUES (7, 'alpha', 'alpha@example.test', 'hash', NULL, '[]', :now)"
            ),
            {"now": NOW},
        )
        connection.execute(
            text(
                "INSERT INTO characters (id, user_id, name, avatar_seed, created_at) "
                "VALUES (9, 7, 'Alpha', 'seed', :now)"
            ),
            {"now": NOW},
        )
        connection.execute(text("UPDATE users SET character_id = 9 WHERE id = 7"))
        connection.execute(
            text(
                "INSERT INTO parties "
                "(id, name, invite_code, owner_id, match_type, max_members, is_open, created_at) "
                "VALUES (11, 'Party', 'ABC123', 7, 'manual', 4, 1, :now)"
            ),
            {"now": NOW},
        )
        connection.execute(
            text(
                "INSERT INTO party_members "
                "(id, party_id, user_id, joined_at, role, status) "
                "VALUES (13, 11, 7, :now, 'owner', 'active')"
            ),
            {"now": NOW},
        )
        connection.execute(
            text(
                "INSERT INTO workouts "
                "(id, user_id, party_id, started_at, status, notes) "
                "VALUES (15, 7, 11, :now, 'ended', 'private note')"
            ),
            {"now": NOW},
        )
        connection.execute(
            text(
                "INSERT INTO setlogs "
                "(id, workout_id, user_id, type, content, created_at) "
                "VALUES (17, 15, 7, 'end', 'complete', :now)"
            ),
            {"now": NOW},
        )
        connection.execute(
            text(
                "INSERT INTO body_stats "
                "(id, character_id, part, level, potential, updated_at) "
                "VALUES (19, 9, 'chest', 2, 40, :now)"
            ),
            {"now": NOW},
        )
        reaction_user_id = 999 if orphan_reaction else 7
        connection.execute(
            text(
                "INSERT INTO reactions "
                "(id, user_id, target_type, target_id, emoji, created_at) "
                "VALUES (21, :user_id, 'workout', 15, 'fire', :now)"
            ),
            {"user_id": reaction_user_id, "now": NOW},
        )
    return engine


def prepare_target(url: str):
    engine = create_engine(url)
    with engine.begin() as connection:
        command.upgrade(alembic_config(connection), "head")
    return engine


def manifest_path(name: str) -> Path:
    path = Path("backend/data") / f"{name}-{uuid4().hex}.manifest.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


def test_transfer_preserves_ids_and_verifies_digests():
    source_url = shared_memory_url("source_success")
    target_url = shared_memory_url("target_success")
    source = prepare_source(source_url)
    target = prepare_target(target_url)
    output = manifest_path("success")
    try:
        migration = migration_module()
        manifest = migration.transfer(source_url, target_url, output)
        report = migration.verify(source_url, target_url)

        assert migration.TABLE_ORDER == TABLE_ORDER
        assert manifest.revision == "20260715_0001"
        assert report.ok is True
        assert all(report.counts[table] == 1 for table in TABLE_ORDER)
        with target.connect() as connection:
            assert connection.execute(
                text("SELECT character_id FROM users WHERE id = 7")
            ).scalar_one() == 9
            assert connection.execute(text("SELECT id FROM reactions")).scalar_one() == 21
        assert output.exists()
        assert "alpha@example.test" not in output.read_text(encoding="utf-8")
    finally:
        output.unlink(missing_ok=True)
        source.dispose()
        target.dispose()


def test_transfer_failure_rolls_back_all_target_rows():
    source_url = shared_memory_url("source_failure")
    target_url = shared_memory_url("target_failure")
    source = prepare_source(source_url, orphan_reaction=True)
    target = prepare_target(target_url)
    output = manifest_path("failure")
    try:
        migration = migration_module()
        with pytest.raises(IntegrityError):
            migration.transfer(source_url, target_url, output)

        with target.connect() as connection:
            for table in TABLE_ORDER:
                count = connection.execute(
                    text(f"SELECT COUNT(*) FROM {table}")
                ).scalar_one()
                assert count == 0
        assert not output.exists()
    finally:
        output.unlink(missing_ok=True)
        source.dispose()
        target.dispose()


def test_transfer_rejects_nonempty_target():
    source_url = shared_memory_url("source_nonempty")
    target_url = shared_memory_url("target_nonempty")
    source = prepare_source(source_url)
    target = prepare_target(target_url)
    with target.begin() as connection:
        connection.execute(
            text(
                "INSERT INTO users "
                "(id, username, email, password_hash, workout_tags, created_at) "
                "VALUES (1, 'existing', 'existing@example.test', 'hash', '[]', :now)"
            ),
            {"now": NOW},
        )
    output = manifest_path("nonempty")
    try:
        migration = migration_module()
        with pytest.raises(ValueError, match="target application tables must be empty"):
            migration.transfer(source_url, target_url, output)
    finally:
        output.unlink(missing_ok=True)
        source.dispose()
        target.dispose()
