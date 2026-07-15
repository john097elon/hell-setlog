# ELO-18 verification evidence

This record separates checks executed in the development workspace from checks that require a Docker runner or provisioned staging infrastructure.

## Local verification

Executed on 2026-07-15 (Asia/Seoul) from branch `agent/elo-18-operational-foundation`:

- `python -m pytest backend/tests -p no:cacheprovider -q`: **48 passed**. The 26 warnings are upstream Python 3.12 SQLite adapter and botocore `utcnow` deprecations.
- `python -m compileall -q backend ops`: passed.
- `node frontend/node_modules/typescript/bin/tsc -b frontend/tsconfig.json`: passed.
- `docker compose config --quiet` and the staging Compose equivalent with placeholder digests: passed.
- Alembic upgraded a blank SQLite verification database to `20260715_0001`; the restored-database application smoke then passed `/healthz`, `/readyz`, registration, login, party creation, and workout creation.
- Workflow YAML parsing, immutable action pins, least-privilege permissions, protected environment use, digest deployment, and previous-digest rollback are enforced by repository contract tests.
- `git diff --check`: passed before the implementation commit.

## External verification still required

- `docker info` reports no `docker_engine` named pipe in this managed workspace. The image build, production-like PostgreSQL/MinIO stack, anonymous storage denial, signed-object fetch, logical backup, and isolated PostgreSQL restore therefore run in the new GitHub Actions verification job.
- A provisioned staging host, DNS name, managed PostgreSQL credentials, private S3-compatible storage credentials, pinned Caddy digest, and protected GitHub environment secrets were not supplied to this task.
- After merge, attach the green workflow URL, published application image digest, staging HTTPS URL, smoke output, backup key/checksum, restore elapsed time/counts, and rollback drill result here or in the release record.

The implementation is reviewable without secrets. Operational acceptance requires the external evidence above; no staging URL or successful live deployment is claimed by this local record.
