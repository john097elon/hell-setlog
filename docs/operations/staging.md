# Staging deployment

The staging stack runs the same application image, Alembic migration entrypoint, private S3-compatible object contract, and same-origin HTTPS edge used by production. GitHub publishes the application image and deploys only a full registry digest through the protected `staging` GitHub environment.

## One-time infrastructure

Provision a Linux host with Docker Engine, Docker Compose v2, `curl`, outbound registry access, public ports 80/443, and persistent Docker volumes. Point the staging DNS name at the host before deployment so Caddy can obtain a certificate. Authenticate Docker on the host to GHCR with a read-only package credential.

Create `/etc/hellsetlog/staging.env`, owned by the deployment user and mode `0600`. Store values in the platform secret manager and render them onto the host; never commit the file. It must include:

```dotenv
APP_ENV=staging
DATABASE_URL=postgresql+psycopg://APP_ROLE:REDACTED@MANAGED_POSTGRES/hellsetlog?sslmode=require
MIGRATION_DATABASE_URL=postgresql+psycopg://MIGRATION_ROLE:REDACTED@MANAGED_POSTGRES/hellsetlog?sslmode=require
CANONICAL_ORIGIN=https://staging.example.com
ALLOWED_HOSTS=["staging.example.com"]
RELEASE=git-sha-or-release-id
STORAGE_BACKEND=s3
STORAGE_BUCKET=private-staging-bucket
STORAGE_REGION=ap-northeast-2
STORAGE_ENDPOINT_URL=https://private-object-endpoint.example
STORAGE_ACCESS_KEY=REDACTED
STORAGE_SECRET_KEY=REDACTED
SENTRY_DSN=https://REDACTED
BACKUP_BUCKET=private-staging-backups
BACKUP_REGION=ap-northeast-2
BACKUP_ENDPOINT_URL=https://private-object-endpoint.example
BACKUP_ACCESS_KEY=REDACTED
BACKUP_SECRET_KEY=REDACTED
CADDY_IMAGE=caddy@sha256:PINNED_MULTIARCH_DIGEST
```

Use managed PostgreSQL 16 or newer. The application role may perform normal DML but not DDL; the migration role owns schema changes. Both the asset and backup buckets must be private, encrypted, versioned, and lifecycle-managed. Pin `CADDY_IMAGE` to a reviewed digest supported by the host architecture.

## Protected GitHub environment

Create a `staging` GitHub environment with required reviewers and deployment branch protection. Add these environment secrets:

- `STAGING_HOST`: DNS name or IP of the deployment host.
- `STAGING_USER`: unprivileged deployment user with Docker access.
- `STAGING_SSH_KEY`: dedicated Ed25519 private key.
- `STAGING_KNOWN_HOSTS`: pre-verified host-key line, never output from live `ssh-keyscan` in CI.
- `STAGING_APP_HOST`: public HTTPS hostname, without a scheme.

The workflow defaults to `contents: read`; only the image publication job receives `packages: write`. External actions are pinned to immutable 40-character commits.

## Deploy and verify

A successful push to `master` runs backend tests, the locked frontend build, Compose model validation, a production-like stack, the core API smoke flow, and an isolated backup/restore rehearsal. It then publishes `ghcr.io/<owner>/<repository>@sha256:<digest>` and invokes the protected staging workflow.

For a controlled manual retry, dispatch **Deploy staging** with the exact full image digest. The host script runs the one-shot Alembic migration, waits for `/readyz`, and executes registration, login, party, and workout creation through the public HTTPS edge. The candidate becomes current only after all checks pass.

## Rollback and incident boundary

The script records the last verified digest in `.deploy-state/.last_image`. If pull, migration, readiness, or smoke fails, it redeploys and verifies the previous image digest. A failed rollback requires immediate operator response and service isolation.

Schema changes must remain backward compatible with the previous image. For data failures, prefer a forward-fix or restore into a new database according to `backup-restore.md`; do not automatically downgrade or overwrite the live database. Record the image digest, Alembic revision, backup key, timestamps, and correlation IDs in the deployment evidence.
