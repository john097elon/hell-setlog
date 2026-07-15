# PostgreSQL backup and restore

Managed PostgreSQL point-in-time recovery is the production recovery source of truth. The repository backup job adds a portable, private custom-format `pg_dump` artifact and a machine-readable success metric.

## Objectives and schedule

| Phase | RPO | RTO | Required proof |
| --- | --- | --- | --- |
| Closed beta | RPO <= 1 hour | RTO <= 4 hours | PITR enabled, hourly logical backup, monthly isolated restore |
| Public beta | RPO <= 5 minutes | RTO <= 1 hour | PITR/WAL retained at least 7 days, daily snapshot retained 30 days, quarterly timed restore |

Backups use a separate least-privilege identity and private bucket/prefix. Enable encryption, versioning, retention, completion monitoring, and a cross-account/region copy when the provider supports it. Never log a database URL, password, object URL, or backup credential.

## Automated backup

Run `python -m ops.backup` from a scheduler at least hourly for closed beta. Supply `DATABASE_URL`, `APP_ENV`, `RELEASE`, `BACKUP_BUCKET`, `BACKUP_REGION`, `BACKUP_ENDPOINT_URL`, `BACKUP_ACCESS_KEY`, and `BACKUP_SECRET_KEY` through the secret store. Set `BACKUP_METRICS_PATH` for the Prometheus textfile collector.

The job runs `pg_dump --format=custom --no-owner --no-acl`, uploads to `backups/{environment}/`, verifies size/checksum with `HeadObject`, deletes the temporary file, and prints one JSON result. Alert if the last-success metric is older than 26 hours.

## Isolated restore rehearsal

Provision an admin URL that may create and drop temporary databases but cannot alter the live production database. Then run:

```powershell
$env:RESTORE_ADMIN_DATABASE_URL = "<secret-managed PostgreSQL admin URL>"
python -m ops.restore_rehearsal --backup-key "backups/staging/20260715T120000Z-release.dump"
```

The command creates a uniquely named database, downloads and verifies one backup, runs `pg_restore --clean --if-exists --no-owner --no-acl --exit-on-error`, checks Alembic revision `20260715_0001`, queries every application table, records elapsed time/counts, and drops the rehearsal database. Set `KEEP_RESTORE_DATABASE=true` only for an approved inspection window and drop it afterward.

After database verification, start the same candidate image against the restored database on an isolated network and run `/readyz` plus the registration, login, party, workout, and history smoke loop. Record image digest, backup key, counts, start/end time, observed RTO, operator, and result. A failed restore is a release blocker.
