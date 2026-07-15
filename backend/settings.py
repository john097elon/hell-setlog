"""Validated environment configuration for Hell Setlog."""

from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import AnyHttpUrl, Field, SecretStr, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

DEFAULT_SQLITE_URL = f"sqlite:///{(Path(__file__).resolve().parent / 'data' / 'hellsetlog.db').as_posix()}"


class Settings(BaseSettings):
    """Application settings with fail-closed deployed-environment validation."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    app_env: Literal["development", "test", "staging", "production"] = "development"
    database_url: str = DEFAULT_SQLITE_URL
    canonical_origin: AnyHttpUrl = "http://localhost:5173"
    allowed_hosts: list[str] = Field(default_factory=lambda: ["localhost", "127.0.0.1"])
    release: str = "development"

    storage_backend: Literal["memory", "local", "s3"] = "local"
    storage_bucket: str = "hellsetlog-development"
    storage_region: str = "us-east-1"
    storage_endpoint_url: AnyHttpUrl | None = None
    storage_access_key: str | None = None
    storage_secret_key: SecretStr | None = None
    storage_local_directory: Path = Path("backend/data/objects")
    storage_max_bytes: int = Field(default=10 * 1024 * 1024, gt=0)

    sentry_dsn: str | None = None
    database_ready_timeout_seconds: float = Field(default=2.0, gt=0, le=10)

    asset_cdn_url: str | None = None
    asset_version: str = "v2"

    @model_validator(mode="after")
    def validate_deployed_environment(self) -> "Settings":
        if self.app_env not in {"staging", "production"}:
            return self

        if not self.database_url.startswith(("postgresql://", "postgresql+psycopg://")):
            raise ValueError("staging and production require PostgreSQL")
        if self.canonical_origin.scheme != "https":
            raise ValueError("canonical origin must use HTTPS")
        if not self.allowed_hosts or "*" in self.allowed_hosts:
            raise ValueError("deployed environments require exact allowed hosts")
        if self.release == "development":
            raise ValueError(
                "deployed environments require an immutable release identifier"
            )

        private_storage_values = (
            self.storage_endpoint_url,
            self.storage_access_key,
            self.storage_secret_key,
            self.sentry_dsn,
        )
        if self.storage_backend != "s3" or any(
            value is None for value in private_storage_values
        ):
            raise ValueError(
                "deployed environments require private S3 storage and error tracking"
            )
        return self


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Return the process-wide validated settings instance."""

    return Settings()
