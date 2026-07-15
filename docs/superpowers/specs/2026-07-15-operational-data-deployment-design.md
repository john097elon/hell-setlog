# ELO-18 operational data and deployment design

Status: accepted via the Stage 1 ELO-19 ADR approval on 2026-07-15

## Goal and boundaries

Move Hell Setlog from a workstation-only SQLite MVP to a reproducible, recoverable staging and production foundation. The accepted direction is managed PostgreSQL 16+, Alembic-only schema management, private S3-compatible media storage, immutable containers, and isolated development, test, staging, and production configuration.

This issue owns the platform seams and their proof: configuration, database connectivity and migrations, SQLite transfer tooling, private-storage adapter and policy, container artifacts, health/readiness, operational telemetry, deployment automation, backup/restore, and rollback documentation. ELO-16 owns the full authentication/session and authorization rewrite. ELO-17 owns the general application test matrix and required CI quality checks. Stage 3 owns the end-user multipart/direct-upload UI and workout-domain integration; ELO-18 supplies the storage contract that work will call.

## Approaches considered

Stage 1 compared retaining SQLite, self-managing PostgreSQL, and using managed PostgreSQL. Retaining SQLite cannot meet concurrent-write or point-in-time recovery requirements. Self-managed PostgreSQL adds patching, HA, and backup operations beyond the beta team's capacity. Managed PostgreSQL plus Alembic is therefore accepted.

For deployment, Stage 1 compared manual deployment, one shared environment, container CI/CD across isolated environments, and Kubernetes. Manual or shared deployment cannot provide isolation or repeatability. Kubernetes adds unjustified beta overhead. Immutable containers promoted through staging are accepted.

For media, a public bucket was rejected because it breaks authorization and deletion guarantees. A private S3-compatible adapter with opaque object keys and short-lived single-object URLs is accepted. A local filesystem adapter exists only for development and tests; staging and production must fail closed unless private S3-compatible storage is configured.

## Architecture

The backend loads one validated settings object. APP_ENV selects development, test, staging, or production behavior. Development and tests may use SQLite and local object emulation. Staging and production require a PostgreSQL URL, exact HTTPS canonical origin and hosts, private object-storage settings, a non-development release identifier, and error-tracking configuration. Secrets come only from the environment or the deployment secret store and never from committed files.

SQLAlchemy creates a pooled engine from DATABASE_URL; SQLite-only connection arguments are conditional. Application startup never calls create_all or executes manual ALTER statements. The deployment entrypoint runs alembic upgrade head using the migration role before starting the application role. /healthz proves the process is alive, while /readyz performs a bounded SELECT 1 and returns a detail-free 503 when the database is unavailable. /api/health remains a minimal compatibility endpoint.

The container build has deterministic backend dependencies and a locked frontend build. The resulting immutable image contains the API and compiled PWA so /api and the browser app share one origin. Local Compose supplies PostgreSQL and a private S3-compatible service. Staging Compose adds an HTTPS edge, separate secrets, persistent volumes, dependency health checks, and a migration job. CI builds the same image once, verifies migrations and smoke behavior, publishes it by digest, and deploys that digest to staging. Production promotion reuses the digest; it does not rebuild.

## Database migration and SQLite transfer

The first Alembic revision is a complete baseline of the current relational model, including named foreign keys, uniqueness, checks, and useful indexes. It must upgrade an empty PostgreSQL database and downgrade only a database created by that revision. Future schema changes use expand/compatible/backfill/contract revisions.

Existing SQLite data moves with a separate, idempotent operator command. It validates that the target schema is at the expected Alembic revision and that the target application tables are empty. It copies rows in dependency order while preserving identifiers, repairs sequences, and records a transfer manifest containing source fingerprint, per-table counts, and deterministic row digests. Verification compares counts, foreign-key validity, and digests before cutover. A failed transfer rolls back its transaction. Operational rollback points the application back to the read-only SQLite snapshot before cutover; after accepted writes begin, recovery uses the captured PostgreSQL restore point rather than reverse-copying into SQLite.

## Private object storage contract

The storage interface accepts generated opaque keys only and exposes operations to put, inspect, create a five-minute GET URL, and delete. Policy rejects objects above the configured byte limit and any content type outside the image allowlist. The adapter never enables public read/list and never returns provider credentials or raw internal bucket URLs. Ownership remains a database concern: callers must authorize a media record before requesting a signed URL or deletion. Stage 3 will add the media record and upload workflow, magic-byte verification, quarantine/scan state, EXIF stripping, and workout/setlog attachment through this interface.

Local tests use an in-memory fake with the same boundary behavior. Development may opt into a local filesystem adapter under a non-public directory, but the app never mounts that directory as static content. Staging and production accept only the S3-compatible implementation.

## Observability and failure handling

Request middleware accepts a valid inbound correlation ID or generates one, returns it in X-Request-ID, and emits one JSON completion event containing environment, release, route template, status, and latency. Logs exclude headers, cookies, emails, bodies, free text, filenames, and signed URLs. Unhandled exceptions include the correlation ID in tracking metadata while the response remains generic. Metrics cover request totals and latency, readiness failures, and process state; the metrics endpoint is intended for the internal network.

Startup configuration errors stop staging/production immediately. Readiness timeouts remove an instance from traffic without leaking dependency details. A storage failure is classified and returned to callers without exposing provider messages. Deployment failure leaves the previous image serving. Migration failure prevents the new application from starting.

## Backup, restore, and rollback

The repository contains an automated PostgreSQL backup job that creates a compressed custom-format dump, encrypts transport through the object-storage endpoint, uploads to a private backup prefix, and emits machine-readable success/failure output for alerting. Managed PostgreSQL PITR remains the production source of truth; logical dumps are an additional portable recovery artifact.

The restore rehearsal creates a new database, restores a selected backup, runs Alembic validation and application smoke checks, and records elapsed time plus row counts. The runbook sets the closed-beta targets to RPO at most one hour and RTO at most four hours, and the public-beta targets to RPO at most five minutes and RTO at most one hour. Application rollback redeploys the previous digest. Database downgrade is allowed only for a revision explicitly marked and rehearsed as safe; otherwise use a feature flag or forward fix. Object policy and asset changes are versioned and reversible.

## Verification

Automated checks prove all of the following:

- settings permit a lightweight development/test configuration but reject unsafe staging/production configuration;
- Alembic upgrades a fresh PostgreSQL database, reaches exactly one head, and performs its safe baseline downgrade;
- a representative legacy SQLite database transfers with matching counts and digests, and a forced failure leaves the target unchanged;
- readiness changes from 200 to detail-free 503 when the database is unavailable;
- storage policy rejects disallowed type, oversize, traversal-like keys, and public URL assumptions, while signed URLs expire after five minutes;
- backend and frontend production builds are reproducible from lock files, the container runs as a non-root user, and the local stack passes its smoke test;
- backup creation, isolated restore, schema check, smoke test, and rollback rehearsal complete through documented commands;
- structured logs and error tracking preserve correlation IDs while redacting sensitive fields.

Actual public DNS, cloud database/object accounts, secret values, TLS certificate issuance, alert receivers, and a deployment host are external environment inputs. The repository provides validated configuration and deployment automation for them, but it cannot manufacture those resources or claim a live staging URL without their credentials.
