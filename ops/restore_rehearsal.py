"""Restore one private backup into a new PostgreSQL database and verify it."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import boto3
from botocore.config import Config as BotoConfig
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL, make_url

from ops.backup import build_pg_environment, failure_result


EXPECTED_REVISION = "20260715_0001"
APPLICATION_TABLES = (
    "users",
    "characters",
    "parties",
    "party_members",
    "workouts",
    "setlogs",
    "body_stats",
    "reactions",
)

class DatabaseRestoreFailed(RuntimeError):
    """The provider-neutral pg_restore stage failed."""


class DatabaseRestoreCleanTargetMissing(DatabaseRestoreFailed):
    """Cleanup referenced an object absent from the isolated target."""


class DatabaseRestoreTargetNotEmpty(DatabaseRestoreFailed):
    """The isolated target contained an object from the archive."""


class DatabaseRestorePermissionDenied(DatabaseRestoreFailed):
    """The restore role could not recreate an archive object."""


class DatabaseRestoreConnectionFailed(DatabaseRestoreFailed):
    """pg_restore could not connect to the isolated target."""


class DatabaseRestoreArchiveIncompatible(DatabaseRestoreFailed):
    """The installed client cannot read the archive format."""


def classify_pg_restore_failure(stderr: bytes | str | None) -> DatabaseRestoreFailed:
    if isinstance(stderr, bytes):
        diagnostic = stderr.decode("utf-8", errors="replace").lower()
    else:
        diagnostic = (stderr or "").lower()
    if "does not exist" in diagnostic:
        return DatabaseRestoreCleanTargetMissing()
    if "already exists" in diagnostic:
        return DatabaseRestoreTargetNotEmpty()
    if "permission denied" in diagnostic:
        return DatabaseRestorePermissionDenied()
    if "connection to server" in diagnostic or "could not connect" in diagnostic:
        return DatabaseRestoreConnectionFailed()
    if "unsupported version" in diagnostic:
        return DatabaseRestoreArchiveIncompatible()
    return DatabaseRestoreFailed()


class RestoredApplicationSmokeFailed(RuntimeError):
    """The restored database could not serve the core application smoke."""


@dataclass(frozen=True)
class RestoreConfig:
    admin_database_url: str
    environment: str
    bucket: str
    region: str
    endpoint_url: str | None
    access_key: str
    secret_key: str
    keep_database: bool = False

    @classmethod
    def from_environment(cls) -> "RestoreConfig":
        required = {
            name: os.environ[name]
            for name in (
                "RESTORE_ADMIN_DATABASE_URL",
                "APP_ENV",
                "BACKUP_BUCKET",
                "BACKUP_ACCESS_KEY",
                "BACKUP_SECRET_KEY",
            )
        }
        return cls(
            admin_database_url=required["RESTORE_ADMIN_DATABASE_URL"],
            environment=required["APP_ENV"],
            bucket=required["BACKUP_BUCKET"],
            region=os.getenv("BACKUP_REGION", "us-east-1"),
            endpoint_url=os.getenv("BACKUP_ENDPOINT_URL"),
            access_key=required["BACKUP_ACCESS_KEY"],
            secret_key=required["BACKUP_SECRET_KEY"],
            keep_database=os.getenv("KEEP_RESTORE_DATABASE", "false").lower() == "true",
        )


def build_pg_restore_command(input_path: Path, database_name: str) -> list[str]:
    return [
        "pg_restore",
        "--dbname",
        database_name,
        "--clean",
        "--if-exists",
        "--no-owner",
        "--no-acl",
        "--exit-on-error",
        str(input_path),
    ]


def build_restore_smoke_command() -> list[str]:
    script = Path(__file__).resolve().parents[1] / "backend" / "scripts" / "smoke_restored_database.py"
    return [sys.executable, str(script)]


def restore_database_name(environment: str, timestamp: str) -> str:
    normalized_environment = re.sub(r"[^a-z0-9]+", "_", environment.lower()).strip("_")
    normalized_timestamp = re.sub(r"[^a-z0-9]+", "", timestamp.lower())
    name = f"hellsetlog_restore_{normalized_environment}_{normalized_timestamp}"
    if not re.fullmatch(r"[a-z0-9_]+", name):
        raise ValueError("restore database name is unsafe")
    return name[:63]


def _s3_client(config: RestoreConfig):
    return boto3.client(
        "s3",
        endpoint_url=config.endpoint_url,
        region_name=config.region,
        aws_access_key_id=config.access_key,
        aws_secret_access_key=config.secret_key,
        config=BotoConfig(signature_version="s3v4", s3={"addressing_style": "path"}),
    )


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _target_url(admin_url: URL, database_name: str) -> str:
    return admin_url.set(database=database_name).render_as_string(hide_password=False)


def _create_database(admin_url: str, database_name: str) -> None:
    engine = create_engine(admin_url, isolation_level="AUTOCOMMIT")
    try:
        with engine.connect() as connection:
            connection.execute(text(f'CREATE DATABASE "{database_name}"'))
    finally:
        engine.dispose()


def _drop_database(admin_url: str, database_name: str) -> None:
    engine = create_engine(admin_url, isolation_level="AUTOCOMMIT")
    try:
        with engine.connect() as connection:
            connection.execute(
                text(
                    "SELECT pg_terminate_backend(pid) FROM pg_stat_activity "
                    "WHERE datname = :name AND pid <> pg_backend_pid()"
                ),
                {"name": database_name},
            )
            connection.execute(text(f'DROP DATABASE IF EXISTS "{database_name}"'))
    finally:
        engine.dispose()


def _verify_database(database_url: str) -> dict[str, int]:
    engine = create_engine(database_url, pool_pre_ping=True)
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1")).scalar_one()
            revision = connection.execute(
                text("SELECT version_num FROM alembic_version")
            ).scalar_one()
            if revision != EXPECTED_REVISION:
                raise RuntimeError("restored Alembic revision is unexpected")
            return {
                table: connection.execute(
                    text(f'SELECT COUNT(*) FROM "{table}"')
                ).scalar_one()
                for table in APPLICATION_TABLES
            }
    finally:
        engine.dispose()


def _run_application_smoke(database_url: str) -> None:
    try:
        subprocess.run(
            build_restore_smoke_command(),
            env={**os.environ, "DATABASE_URL": database_url},
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as error:
        raise RestoredApplicationSmokeFailed from error


def run_restore_rehearsal(
    config: RestoreConfig,
    backup_key: str,
) -> dict[str, Any]:
    started = time.monotonic()
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    database_name = restore_database_name(config.environment, timestamp)
    admin_url = make_url(config.admin_database_url)
    if not admin_url.drivername.startswith("postgresql"):
        raise ValueError("restore rehearsal requires PostgreSQL")
    database_url = _target_url(admin_url, database_name)
    database_created = False

    try:
        _create_database(config.admin_database_url, database_name)
        database_created = True
        with tempfile.TemporaryDirectory(prefix="hellsetlog-restore-") as directory:
            backup_path = Path(directory) / "database.dump"
            client = _s3_client(config)
            metadata = client.head_object(Bucket=config.bucket, Key=backup_key)
            client.download_file(config.bucket, backup_key, str(backup_path))
            expected_checksum = metadata.get("Metadata", {}).get("sha256")
            if expected_checksum and _sha256(backup_path) != expected_checksum:
                raise RuntimeError("downloaded backup checksum verification failed")
            if backup_path.stat().st_size != int(metadata["ContentLength"]):
                raise RuntimeError("downloaded backup size verification failed")

            try:
                subprocess.run(
                    build_pg_restore_command(backup_path, database_name),
                    env={**os.environ, **build_pg_environment(database_url)},
                    check=True,
                    capture_output=True,
                )
            except subprocess.CalledProcessError as error:
                raise classify_pg_restore_failure(error.stderr) from error
        counts = _verify_database(database_url)
        _run_application_smoke(database_url)
        return {
            "status": "ok",
            "backup_key": backup_key,
            "database_name": database_name,
            "revision": EXPECTED_REVISION,
            "counts": counts,
            "application_smoke": "ok",
            "duration_seconds": round(time.monotonic() - started, 3),
            "kept_for_inspection": config.keep_database,
        }
    finally:
        if database_created and not config.keep_database:
            _drop_database(config.admin_database_url, database_name)


def main() -> int:
    parser = argparse.ArgumentParser(description="Rehearse an isolated PostgreSQL restore")
    parser.add_argument("--backup-key", required=True)
    args = parser.parse_args()
    try:
        result = run_restore_rehearsal(
            RestoreConfig.from_environment(),
            args.backup_key,
        )
    except Exception as error:
        print(json.dumps(failure_result(error), sort_keys=True))
        return 1
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
