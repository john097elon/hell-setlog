import importlib
import importlib.util

from sqlalchemy import text


def load_modules():
    assert importlib.util.find_spec("settings") is not None, "settings module must exist"
    settings_module = importlib.import_module("settings")
    database_module = importlib.import_module("database")
    assert hasattr(database_module, "create_database_engine"), "database engine factory must exist"
    return settings_module, database_module


def test_create_database_engine_uses_requested_sqlite_url():
    settings_module, database_module = load_modules()
    database_url = "sqlite://"
    settings = settings_module.Settings(
        _env_file=None,
        app_env="test",
        database_url=database_url,
        storage_backend="memory",
    )

    engine = database_module.create_database_engine(settings)

    assert str(engine.url) == database_url
    with engine.connect() as connection:
        assert connection.execute(text("SELECT 1")).scalar_one() == 1


def test_create_database_engine_enables_pre_ping_for_postgres():
    settings_module, database_module = load_modules()
    settings = settings_module.Settings(
        _env_file=None,
        app_env="development",
        database_url="postgresql+psycopg://app:secret@localhost/hellsetlog",
    )

    engine = database_module.create_database_engine(settings)

    assert engine.pool._pre_ping is True
    engine.dispose()
