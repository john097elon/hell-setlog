"""Portable PostgreSQL backup job with private object upload."""

from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import tempfile
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import boto3
from botocore.config import Config as BotoConfig
from sqlalchemy.engine import make_url


@dataclass(frozen=True)
class BackupConfig:
    database_url: str
    environment: str
    release: str
    bucket: str
    region: str
    endpoint_url: str | None
    access_key: str
    secret_key: str
    metrics_path: Path | None = None
    server_side_encryption: str | None = None

    @classmethod
    def from_environment(cls) -> "BackupConfig":
        required = {
            name: os.environ[name]
            for name in (
                "DATABASE_URL",
                "APP_ENV",
                "RELEASE",
                "BACKUP_BUCKET",
                "BACKUP_ACCESS_KEY",
                "BACKUP_SECRET_KEY",
            )
        }
        return cls(
            database_url=required["DATABASE_URL"],
            environment=required["APP_ENV"],
            release=required["RELEASE"],
            bucket=required["BACKUP_BUCKET"],
            region=os.getenv("BACKUP_REGION", "us-east-1"),
            endpoint_url=os.getenv("BACKUP_ENDPOINT_URL"),
            access_key=required["BACKUP_ACCESS_KEY"],
            secret_key=required["BACKUP_SECRET_KEY"],
            metrics_path=(
                Path(os.environ["BACKUP_METRICS_PATH"])
                if os.getenv("BACKUP_METRICS_PATH")
                else None
            ),
            server_side_encryption=os.getenv("BACKUP_SERVER_SIDE_ENCRYPTION"),
        )


def build_pg_environment(database_url: str) -> dict[str, str]:
    url = make_url(database_url)
    if not url.drivername.startswith("postgresql"):
        raise ValueError("backup requires a PostgreSQL database URL")
    if not url.host or not url.username or not url.database:
        raise ValueError("database URL must include host, user, and database")

    environment = {
        "PGHOST": url.host,
        "PGPORT": str(url.port or 5432),
        "PGUSER": url.username,
        "PGDATABASE": url.database,
        "PGSSLMODE": str(url.query.get("sslmode", "require")),
    }
    if url.password is not None:
        environment["PGPASSWORD"] = url.password
    return environment


def build_pg_dump_command(output_path: Path) -> list[str]:
    return [
        "pg_dump",
        "--format=custom",
        "--no-owner",
        "--no-acl",
        "--file",
        str(output_path),
    ]


def failure_result(error: Exception) -> dict[str, str]:
    return {"status": "failed", "error_type": type(error).__name__}


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _safe_component(value: str) -> str:
    safe = re.sub(r"[^a-zA-Z0-9._-]+", "-", value).strip("-")
    if not safe:
        raise ValueError("backup key component is empty after sanitization")
    return safe


def _s3_client(config: BackupConfig):
    return boto3.client(
        "s3",
        endpoint_url=config.endpoint_url,
        region_name=config.region,
        aws_access_key_id=config.access_key,
        aws_secret_access_key=config.secret_key,
        config=BotoConfig(signature_version="s3v4", s3={"addressing_style": "path"}),
    )


def _write_success_metric(path: Path | None, completed_epoch: float) -> None:
    if path is None:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        "# HELP hellsetlog_backup_last_success_timestamp_seconds "
        "Unix time of the last successful backup.\n"
        "# TYPE hellsetlog_backup_last_success_timestamp_seconds gauge\n"
        f"hellsetlog_backup_last_success_timestamp_seconds {completed_epoch:.0f}\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def run_backup(config: BackupConfig) -> dict[str, Any]:
    started = time.monotonic()
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    key = (
        f"backups/{_safe_component(config.environment)}/"
        f"{timestamp}-{_safe_component(config.release)}.dump"
    )

    with tempfile.TemporaryDirectory(prefix="hellsetlog-backup-") as directory:
        backup_path = Path(directory) / "database.dump"
        process_environment = {
            **os.environ,
            **build_pg_environment(config.database_url),
        }
        subprocess.run(
            build_pg_dump_command(backup_path),
            env=process_environment,
            check=True,
            capture_output=True,
        )
        checksum = _sha256(backup_path)
        size_bytes = backup_path.stat().st_size

        extra_args: dict[str, Any] = {"Metadata": {"sha256": checksum}}
        if config.server_side_encryption:
            extra_args["ServerSideEncryption"] = config.server_side_encryption
        client = _s3_client(config)
        client.upload_file(
            str(backup_path),
            config.bucket,
            key,
            ExtraArgs=extra_args,
        )
        uploaded = client.head_object(Bucket=config.bucket, Key=key)
        if int(uploaded["ContentLength"]) != size_bytes:
            raise RuntimeError("uploaded backup size verification failed")
        if uploaded.get("Metadata", {}).get("sha256") != checksum:
            raise RuntimeError("uploaded backup checksum verification failed")

    completed_epoch = time.time()
    _write_success_metric(config.metrics_path, completed_epoch)
    return {
        "status": "ok",
        "key": key,
        "size_bytes": size_bytes,
        "checksum_sha256": checksum,
        "duration_seconds": round(time.monotonic() - started, 3),
        "completed_at": datetime.fromtimestamp(
            completed_epoch, timezone.utc
        ).isoformat(),
    }


def main() -> int:
    try:
        result = run_backup(BackupConfig.from_environment())
    except Exception as error:
        print(json.dumps(failure_result(error), sort_keys=True))
        return 1
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
