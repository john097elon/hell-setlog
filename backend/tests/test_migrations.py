from pathlib import Path

from alembic import command
from alembic.config import Config
from alembic.script import ScriptDirectory
from sqlalchemy import CheckConstraint, DateTime, create_engine, inspect

from database import Base
import models  # noqa: F401


def alembic_config(connection=None) -> Config:
    config = Config("backend/alembic.ini")
    config.set_main_option("script_location", "backend/migrations")
    config.set_main_option("sqlalchemy.url", "sqlite://")
    if connection is not None:
        config.attributes["connection"] = connection
    return config


def test_migrations_have_one_head():
    script = ScriptDirectory.from_config(alembic_config())

    assert script.get_heads() == ["20260715_0001"]


def test_baseline_upgrades_and_downgrades_fresh_database():
    engine = create_engine("sqlite://")
    with engine.begin() as connection:
        config = alembic_config(connection)
        command.upgrade(config, "head")
        assert set(inspect(connection).get_table_names()) >= {
            "alembic_version",
            "users",
            "characters",
            "parties",
            "party_members",
            "workouts",
            "setlogs",
            "body_stats",
            "reactions",
        }
        command.downgrade(config, "base")
        assert inspect(connection).get_table_names() == ["alembic_version"]


def test_runtime_does_not_mutate_schema():
    for path in (Path("backend/main.py"), Path("backend/seed.py")):
        source = path.read_text(encoding="utf-8")
        assert "create_all" not in source
        assert "init_db" not in source
        assert "ALTER TABLE" not in source


def test_model_metadata_matches_operational_baseline():
    constraint_names = {
        constraint.name
        for table in Base.metadata.tables.values()
        for constraint in table.constraints
        if isinstance(constraint, CheckConstraint)
    }
    index_names = {
        index.name
        for table in Base.metadata.tables.values()
        for index in table.indexes
    }

    assert {
        "ck_parties_max_members_positive",
        "ck_party_member_role",
        "ck_party_member_status",
        "ck_workouts_status",
    } <= constraint_names
    assert {
        "ix_party_members_party_status",
        "ix_workouts_user_started_at",
        "ix_workouts_party_started_at",
        "ix_setlogs_workout_created_at",
        "ix_reactions_target",
    } <= index_names

    datetime_columns = [
        column
        for table in Base.metadata.tables.values()
        for column in table.columns
        if isinstance(column.type, DateTime)
    ]
    assert datetime_columns
    assert all(column.type.timezone for column in datetime_columns)
