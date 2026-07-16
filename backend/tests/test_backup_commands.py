import importlib
import importlib.util
import json
import sys
from pathlib import Path

import yaml


def operations_module(name: str):
    module_name = f"ops.{name}"
    assert importlib.util.find_spec(module_name) is not None, (
        f"{module_name} must exist"
    )
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

    command = restore.build_pg_restore_command(
        Path("/tmp/backup.dump"),
        "hellsetlog_restore_test_20260715t120000z",
    )

    assert command == [
        "pg_restore",
        "--dbname",
        "hellsetlog_restore_test_20260715t120000z",
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
    error = RuntimeError("failed postgresql://app:super-secret@db.example/hellsetlog")

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
        "postgresql+psycopg://hellsetlog:hellsetlog@db:5432/hellsetlog?sslmode=disable"
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


def test_restore_subprocess_failures_have_safe_stage_specific_types():
    backup = operations_module("backup")
    restore = operations_module("restore_rehearsal")

    restore_failure = backup.failure_result(restore.DatabaseRestoreFailed())
    smoke_failure = backup.failure_result(restore.RestoredApplicationSmokeFailed())

    assert restore_failure == {
        "status": "failed",
        "error_type": "DatabaseRestoreFailed",
    }
    assert smoke_failure == {
        "status": "failed",
        "error_type": "RestoredApplicationSmokeFailed",
    }


def test_pg_restore_diagnostics_are_classified_without_raw_output():
    restore = operations_module("restore_rehearsal")

    assert (
        type(
            restore.classify_pg_restore_failure(
                b'pg_restore: error: relation "public.users" does not exist'
            )
        ).__name__
        == "DatabaseRestoreCleanTargetMissing"
    )
    assert (
        type(
            restore.classify_pg_restore_failure(
                b'pg_restore: error: relation "users" already exists'
            )
        ).__name__
        == "DatabaseRestoreTargetNotEmpty"
    )
    assert (
        type(
            restore.classify_pg_restore_failure(b"pg_restore: error: permission denied")
        ).__name__
        == "DatabaseRestorePermissionDenied"
    )
    assert (
        type(
            restore.classify_pg_restore_failure(
                b"pg_restore: error: connection to server failed"
            )
        ).__name__
        == "DatabaseRestoreConnectionFailed"
    )
    assert (
        type(
            restore.classify_pg_restore_failure(
                b"pg_restore: unsupported version in file header"
            )
        ).__name__
        == "DatabaseRestoreArchiveIncompatible"
    )
    assert type(restore.classify_pg_restore_failure(b"unclassified")).__name__ == (
        "DatabaseRestoreFailed"
    )


def test_pg_restore_diagnostic_keeps_only_a_redacted_first_line():
    restore = operations_module("restore_rehearsal")
    raw = (
        b'pg_restore: error: relation "private_table" failed for '
        b"postgresql://user:secret@db/private\n"
        b"DETAIL: user@example.com and row data"
    )

    diagnostic = restore.safe_pg_restore_diagnostic(raw)

    assert restore.safe_pg_restore_diagnostic(b"") == "pg_restore failed"

    assert diagnostic == (
        'pg_restore: error: relation "<redacted>" failed for postgresql://<redacted>'
    )
    assert "private_table" not in diagnostic
    assert "secret" not in diagnostic
    assert "example.com" not in diagnostic
    assert "row data" not in diagnostic


def test_restore_failure_result_includes_only_safe_diagnostic():
    restore = operations_module("restore_rehearsal")
    error = restore.DatabaseRestoreFailed("safe reason")

    assert restore.restore_failure_result(error) == {
        "status": "failed",
        "error_type": "DatabaseRestoreFailed",
        "diagnostic": "safe reason",
    }

def test_restore_rehearsal_tracks_current_workout_record_schema():
    restore = operations_module("restore_rehearsal")
    assert restore.EXPECTED_REVISION == "20260716_0003"
    assert {"exercises", "workout_records", "exercise_sets"} <= set(
        restore.APPLICATION_TABLES
    )
