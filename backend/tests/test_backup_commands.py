import importlib
import importlib.util
import json
import sys

import yaml
from pathlib import Path


def operations_module(name: str):
    module_name = f"ops.{name}"
    assert importlib.util.find_spec(module_name) is not None, f"{module_name} must exist"
    return importlib.import_module(module_name)


def test_pg_dump_uses_environment_not_database_url():
    backup = operations_module("backup")
    database_url = "postgresql+psycopg://app:super-secret@db.example:5432/hellsetlog?sslmode=require"

    environment = backup.build_pg_environment(database_url)
    command = backup.build_pg_dump_command(Path("/tmp/backup.dump"))

    assert environment["PGHOST"] == "db.example"
    assert environment["PGPORT"] == "5432"
    assert environment["PGUSER"] == "app"
    assert environment["PGPASSWORD"] == "super-secret"
    assert environment["PGDATABASE"] == "hellsetlog"
    assert environment["PGSSLMODE"] == "require"
    assert command == [
        "pg_dump",
        "--format=custom",
        "--no-owner",
        "--no-acl",
        "--file",
        str(Path("/tmp/backup.dump")),
    ]
    assert database_url not in " ".join(command)


def test_pg_restore_is_clean_ownerless_and_stops_on_error():
    restore = operations_module("restore_rehearsal")

    command = restore.build_pg_restore_command(Path("/tmp/backup.dump"))

    assert command == [
        "pg_restore",
        "--clean",
        "--if-exists",
        "--no-owner",
        "--no-acl",
        "--exit-on-error",
        str(Path("/tmp/backup.dump")),
    ]


def test_restore_database_name_is_generated_and_safe():
    restore = operations_module("restore_rehearsal")

    name = restore.restore_database_name("staging", "20260715T120000Z")

    assert name == "hellsetlog_restore_staging_20260715t120000z"
    assert name.replace("_", "").isalnum()
    assert name == name.lower()


def test_failure_result_never_serializes_secret_or_url():
    backup = operations_module("backup")
    error = RuntimeError(
        "failed postgresql://app:super-secret@db.example/hellsetlog"
    )

    payload = json.dumps(backup.failure_result(error), sort_keys=True)

    assert payload == '{"error_type": "RuntimeError", "status": "failed"}'
    assert "super-secret" not in payload
    assert "postgresql" not in payload


def test_recovery_runbooks_define_objectives_and_rollback_boundary():
    backup_runbook = Path("docs/operations/backup-restore.md")
    rollback_runbook = Path("docs/operations/deploy-rollback.md")

    assert backup_runbook.exists()
    assert rollback_runbook.exists()
    backup_source = backup_runbook.read_text(encoding="utf-8")
    rollback_source = rollback_runbook.read_text(encoding="utf-8")

    assert "RPO <= 1 hour" in backup_source
    assert "RTO <= 4 hours" in backup_source
    assert "RPO <= 5 minutes" in backup_source
    assert "RTO <= 1 hour" in backup_source
    assert "previous image digest" in rollback_source
    assert "forward-fix" in rollback_source
    assert "downgrade" in rollback_source


def test_local_stack_contains_hourly_automated_backup_job():
    dockerfile = Path("Dockerfile").read_text(encoding="utf-8")
    compose = Path("docker-compose.yml").read_text(encoding="utf-8")
    loop = Path("ops/backup_loop.sh")

    assert "COPY ops/ /app/ops/" in dockerfile
    assert loop.exists()
    assert "backup:" in compose
    assert "BACKUP_INTERVAL_SECONDS: 3600" in compose
    loop_source = loop.read_text(encoding="utf-8")
    assert "python -m ops.backup" in loop_source
    assert "BACKUP_INTERVAL_SECONDS" in loop_source
    assert "sleep" in loop_source

def test_restore_rehearsal_defines_application_readiness_smoke():
    restore = operations_module("restore_rehearsal")
    command = restore.build_restore_smoke_command()
    script = Path("backend/scripts/smoke_restored_database.py")

    assert command == [sys.executable, str(script.resolve())]
    assert script.exists()
    source = script.read_text(encoding="utf-8")
    assert '"/healthz"' in source
    assert '"/readyz"' in source
    assert '"/api/auth/register"' in source
    assert '"/api/parties/"' in source

def test_restore_smoke_uses_only_the_isolated_database_url(monkeypatch):
    restore = operations_module("restore_rehearsal")
    invocation = {}

    def fake_run(command, **kwargs):
        invocation["command"] = command
        invocation.update(kwargs)

    monkeypatch.setattr(restore.subprocess, "run", fake_run)
    restored_url = "postgresql+psycopg://app:secret@db/restored"

    restore._run_application_smoke(restored_url)

    assert invocation["command"] == restore.build_restore_smoke_command()
    assert invocation["env"]["DATABASE_URL"] == restored_url
    assert invocation["check"] is True
    assert invocation["capture_output"] is True
    assert invocation["text"] is True
    assert "shell" not in invocation

def test_local_recovery_explicitly_disables_tls_only_for_compose_postgres():
    compose = Path("docker-compose.yml").read_text(encoding="utf-8")
    workflow = Path(".github/workflows/operational-foundation.yml").read_text(
        encoding="utf-8"
    )
    local_url = (
        "postgresql+psycopg://hellsetlog:hellsetlog@db:5432/"
        "hellsetlog?sslmode=disable"
    )

    assert f"DATABASE_URL: {local_url}" in compose
    assert f"MIGRATION_DATABASE_URL: {local_url}" in compose
    assert f"RESTORE_ADMIN_DATABASE_URL={local_url}" in workflow

def test_backup_metrics_volume_has_a_bounded_ownership_initializer():
    for path in (Path("docker-compose.yml"), Path("compose.staging.yml")):
        compose = yaml.safe_load(path.read_text(encoding="utf-8"))
        services = compose["services"]
        initializer = services["backup-metrics-init"]

        assert initializer["user"] == "0:0"
        assert initializer["read_only"] is True
        assert initializer["restart"] == "no"
        assert initializer["command"] == [
            "sh",
            "-c",
            "chown -R 10001:10001 /metrics",
        ]
        assert initializer["volumes"] == ["backup-metrics:/metrics"]
        assert services["backup"]["depends_on"]["backup-metrics-init"] == {
            "condition": "service_completed_successfully"
        }
