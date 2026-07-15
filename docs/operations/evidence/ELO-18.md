# ELO-18 verification evidence

This record separates checks executed in the development workspace, checks executed on a Docker-capable CI runner, and the remaining live staging acceptance gate.

## Local verification

Executed on 2026-07-15 (Asia/Seoul) from branch `agent/elo-18-operational-foundation`:

- `python -m pytest backend/tests -p no:cacheprovider -q`: **54 passed**. The 26 warnings are upstream Python 3.12 SQLite adapter and botocore `utcnow` deprecations.
- `python -m compileall -q backend ops`: passed.
- `node frontend/node_modules/typescript/bin/tsc -b frontend/tsconfig.json`: passed.
- `docker compose config --quiet` and the staging Compose equivalent with placeholder digests: passed.
- Alembic upgraded a blank SQLite verification database to `20260715_0001`; the restored-database application smoke then passed `/healthz`, `/readyz`, registration, login, party creation, and workout creation.
- Workflow YAML parsing, immutable action pins, least-privilege permissions, protected environment use, digest deployment, and previous-digest rollback are enforced by repository contract tests.
- `git diff --check`: passed before each implementation commit.

## GitHub Actions verification

[Operational foundation run 29393481419](https://github.com/john097elon/hell-setlog/actions/runs/29393481419) passed on 2026-07-15 UTC against commit `f0452a3`:

- Backend contracts: **54 passed**; the locked frontend/PWA build completed both directly and inside the multi-stage image.
- The production-like PostgreSQL 16, MinIO, migration, non-root app, and backup services reached their dependency/health gates.
- The HTTP core flow passed health, registration, login, party creation, and workout creation.
- Private storage smoke denied anonymous object read and list, accepted an exact 300-second signed fetch, and verified deletion.
- Backup `backups/development/20260715T061311Z-local-compose.dump` uploaded 28,126 bytes with SHA-256 `b3ab934a6788a5a4a9cc315d4d6e594df519068a43f64cc946b1aa0f41cce4cd` in 0.305 seconds.
- Restore created isolated database `hellsetlog_restore_development_20260715t061312z`, restored revision `20260715_0001`, and verified counts: users 1, characters 1, parties 1, party_members 1, workouts 1, body_stats 7, setlogs 0, reactions 0.
- The restored database core application smoke returned `application_smoke: ok`; total restore verification took 3.271 seconds and the isolated database was removed afterward.
- Compose teardown removed containers, network, and test volumes.

## External verification still required

- Image publication is intentionally master-only, so the PR run did not publish a GHCR application digest.
- A provisioned staging host, DNS name, managed PostgreSQL credentials, private S3-compatible storage credentials, pinned Caddy digest, and protected GitHub environment secrets were not supplied to this task.
- After merge, attach the published application image digest, protected staging workflow URL, staging HTTPS URL, smoke output, and a previous-digest rollback drill result here or in the release record.

The implementation and production-like recovery path are verified without cloud secrets. Operational acceptance still requires the live staging evidence above; no staging URL or successful live deployment is claimed by this record.
