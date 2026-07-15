import importlib
import importlib.util

import pytest
from pydantic import ValidationError

DEPLOYED_ENV = {
    "app_env": "staging",
    "database_url": "postgresql+psycopg://app:secret@db/hellsetlog",
    "canonical_origin": "https://staging.hellsetlog.example",
    "allowed_hosts": ["staging.hellsetlog.example"],
    "release": "sha-abc123",
    "storage_backend": "s3",
    "storage_bucket": "hellsetlog-staging",
    "storage_endpoint_url": "https://objects.example",
    "storage_access_key": "access-key",
    "storage_secret_key": "secret-key",
    "sentry_dsn": "https://public@example.ingest.sentry.io/1",
}


def settings_class():
    assert importlib.util.find_spec("settings") is not None, "settings module must exist"
    return importlib.import_module("settings").Settings


def test_test_environment_accepts_sqlite():
    settings = settings_class()(
        _env_file=None,
        app_env="test",
        database_url="sqlite://",
        storage_backend="memory",
    )

    assert settings.app_env == "test"
    assert settings.database_url == "sqlite://"


def test_production_rejects_sqlite():
    values = {**DEPLOYED_ENV, "app_env": "production", "database_url": "sqlite:///prod.db"}

    with pytest.raises(ValidationError, match="PostgreSQL"):
        settings_class()(_env_file=None, **values)


def test_staging_requires_private_s3_and_error_tracking():
    values = {**DEPLOYED_ENV, "storage_backend": "local", "sentry_dsn": None}

    with pytest.raises(ValidationError, match="private S3 storage and error tracking"):
        settings_class()(_env_file=None, **values)


def test_complete_staging_configuration_is_accepted():
    settings = settings_class()(_env_file=None, **DEPLOYED_ENV)

    assert str(settings.canonical_origin) == "https://staging.hellsetlog.example/"
    assert settings.allowed_hosts == ["staging.hellsetlog.example"]
