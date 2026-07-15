# Operational Data and Deployment Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the SQLite/startup-mutation MVP foundation with validated environments, PostgreSQL/Alembic, private object storage, immutable deployment artifacts, operational telemetry, and rehearsable recovery.

**Architecture:** A validated settings module creates environment-specific database and storage dependencies. Alembic owns schema state, an operator tool moves legacy SQLite rows into PostgreSQL, and one immutable image serves the API and compiled PWA behind an HTTPS edge. Deployment, backup, restore, and rollback commands are repository-owned and verified against a local production-like stack.

**Tech Stack:** Python 3.12, FastAPI 0.115, Pydantic Settings 2.x, SQLAlchemy 2.0, Alembic 1.13, psycopg 3, boto3, structlog, prometheus-client, Sentry SDK, PostgreSQL 16, MinIO, React 18, Vite 6, Docker Compose, Caddy, GitHub Actions.

## Global Constraints

- Staging and production require PostgreSQL 16+, exact HTTPS origin/hosts, private S3-compatible storage, release ID, and error-tracking DSN.
- Development and test may use SQLite and fake/local storage; staging and production may not.
- Alembic is the only schema mechanism; runtime create_all and manual ALTER are removed.
- Signed object URLs expire after exactly 300 seconds and buckets never allow public read or list.
- The closed-beta recovery targets are RPO <= 1 hour and RTO <= 4 hours; public beta targets are RPO <= 5 minutes and RTO <= 1 hour.
- Application logs never include auth headers, cookies, email, request bodies, free text, filenames, object URLs, or secret values.
- Public DNS, cloud accounts, TLS credentials, alert receivers, and deployment hosts are external inputs and must not be fabricated in tests or documentation.
- ELO-16 owns opaque sessions/authz and ELO-17 owns general quality gates; this plan exposes clean integration seams without duplicating those changes.

---

### Task 1: Validated environment settings and database engine

**Files:**
- Create: `backend/settings.py`
- Create: `backend/tests/conftest.py`
- Create: `backend/tests/test_settings.py`
- Create: `backend/tests/test_database.py`
- Modify: `backend/database.py`
- Modify: `backend/requirements.txt`
- Modify: `.gitignore`
- Create: `.env.example`

**Interfaces:**
- Produces: `Settings`, `get_settings() -> Settings`, `create_database_engine(settings: Settings) -> Engine`, `engine`, `SessionLocal`, and `get_db()`.
- Consumes: existing SQLAlchemy models import `Base` from `database`.

- [ ] **Step 1: Add failing configuration tests**

```python
def test_production_rejects_sqlite(monkeypatch):
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("DATABASE_URL", "sqlite:///prod.db")
    with pytest.raises(ValidationError, match="PostgreSQL"):
        Settings()

def test_test_environment_accepts_sqlite(monkeypatch, tmp_path):
    monkeypatch.setenv("APP_ENV", "test")
    monkeypatch.setenv("DATABASE_URL", f"sqlite:///{tmp_path / 'test.db'}")
    assert Settings().app_env == "test"
```

- [ ] **Step 2: Run the settings tests and observe the missing module**

Run: `python -m pytest backend/tests/test_settings.py -q`
Expected: FAIL with `ModuleNotFoundError: No module named 'settings'`.

- [ ] **Step 3: Implement Settings with staging/production model validation**

```python
class Settings(BaseSettings):
    app_env: Literal["development", "test", "staging", "production"] = "development"
    database_url: str = "sqlite:///./data/hellsetlog.db"
    canonical_origin: AnyHttpUrl = "http://localhost:5173"
    allowed_hosts: list[str] = ["localhost", "127.0.0.1"]
    release: str = "development"
    storage_backend: Literal["memory", "local", "s3"] = "local"
    storage_bucket: str = "hellsetlog-dev"
    storage_endpoint_url: AnyHttpUrl | None = None
    storage_access_key: str | None = None
    storage_secret_key: SecretStr | None = None
    sentry_dsn: str | None = None

    @model_validator(mode="after")
    def validate_deployed_environment(self):
        if self.app_env in {"staging", "production"}:
            if not self.database_url.startswith(("postgresql://", "postgresql+psycopg://")):
                raise ValueError("staging and production require PostgreSQL")
            if self.canonical_origin.scheme != "https":
                raise ValueError("canonical origin must use HTTPS")
            required = [self.storage_endpoint_url, self.storage_access_key, self.storage_secret_key, self.sentry_dsn]
            if self.storage_backend != "s3" or any(value is None for value in required):
                raise ValueError("deployed environments require private S3 storage and error tracking")
        return self
```

- [ ] **Step 4: Refactor database.py to use the validated URL**

```python
def create_database_engine(settings: Settings) -> Engine:
    kwargs: dict[str, object] = {"pool_pre_ping": True}
    if settings.database_url.startswith("sqlite"):
        kwargs["connect_args"] = {"check_same_thread": False}
    else:
        kwargs.update(pool_size=5, max_overflow=10, pool_recycle=1800)
    return create_engine(settings.database_url, **kwargs)
```

Delete `_sqlite_columns`, `_add_column_if_missing`, `migrate_sqlite`, and `init_db`.

- [ ] **Step 5: Install locked runtime/test dependencies and run focused tests**

Add exact pins for `alembic`, `psycopg[binary]`, `pydantic-settings`, `boto3`, `structlog`, `prometheus-client`, `sentry-sdk[fastapi]`, `pytest`, and `httpx`. Run: `python -m pytest backend/tests/test_settings.py backend/tests/test_database.py -q`. Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add backend/settings.py backend/database.py backend/requirements.txt backend/tests .env.example .gitignore
git commit -m "feat(ELO-18): validate environments and database configuration"
```

### Task 2: Alembic baseline and runtime migration removal

**Files:**
- Create: `backend/alembic.ini`
- Create: `backend/migrations/env.py`
- Create: `backend/migrations/script.py.mako`
- Create: `backend/migrations/versions/20260715_0001_baseline.py`
- Create: `backend/tests/test_migrations.py`
- Modify: `backend/main.py`
- Modify: `backend/seed.py`

**Interfaces:**
- Produces: Alembic revision `20260715_0001` and CLI `alembic -c backend/alembic.ini upgrade head`.
- Consumes: `settings.database_url` and `models.Base.metadata`.

- [ ] **Step 1: Write migration graph and runtime-mutation tests**

```python
def test_migrations_have_one_head(alembic_config):
    script = ScriptDirectory.from_config(alembic_config)
    assert script.get_heads() == ["20260715_0001"]

def test_main_does_not_mutate_schema():
    source = Path("backend/main.py").read_text(encoding="utf-8")
    assert "create_all" not in source
    assert "init_db" not in source
```

- [ ] **Step 2: Run tests and confirm Alembic files are missing**

Run: `python -m pytest backend/tests/test_migrations.py -q`. Expected: FAIL because `backend/alembic.ini` does not exist.

- [ ] **Step 3: Create an explicit portable baseline**

The revision creates, in dependency-safe order, `users`, `characters`, the named `fk_user_character`, `parties`, `party_members`, `workouts`, `setlogs`, `body_stats`, and `reactions`. Preserve every current named unique/check constraint and add indexes for workout history, feed ordering, and active membership lookups. The downgrade drops in reverse order.

- [ ] **Step 4: Configure env.py without logging secrets**

```python
config.set_main_option("sqlalchemy.url", get_settings().database_url.replace("%", "%%"))
target_metadata = Base.metadata
context.configure(connection=connection, target_metadata=target_metadata, compare_type=True)
```

- [ ] **Step 5: Remove startup/seed schema mutation and verify a fresh database**

Run: `alembic -c backend/alembic.ini upgrade head`, `alembic -c backend/alembic.ini current`, then `alembic -c backend/alembic.ini downgrade base`. Expected revisions: head, `20260715_0001`, then base.

- [ ] **Step 6: Commit**

```bash
git add backend/alembic.ini backend/migrations backend/main.py backend/seed.py backend/tests/test_migrations.py
git commit -m "feat(ELO-18): establish Alembic schema baseline"
```

### Task 3: Transactional SQLite-to-PostgreSQL transfer

**Files:**
- Create: `backend/scripts/migrate_sqlite_to_postgres.py`
- Create: `backend/tests/test_sqlite_transfer.py`
- Create: `docs/operations/sqlite-cutover.md`

**Interfaces:**
- Produces: `transfer(source_url: str, target_url: str, manifest_path: Path) -> TransferManifest` and `verify(source_url: str, target_url: str) -> VerificationReport`.
- Consumes: Alembic revision `20260715_0001` and the current table set.

- [ ] **Step 1: Write a failing transfer test with representative relationships**

Create a source SQLite database containing a user/character cycle, owner party membership, workout, setlog, body stat, and reaction. Assert preserved IDs, equal per-table counts/digests, and an empty target after an injected failure.

- [ ] **Step 2: Run the transfer test and observe the missing module**

Run: `python -m pytest backend/tests/test_sqlite_transfer.py -q`. Expected: FAIL with missing `migrate_sqlite_to_postgres`.

- [ ] **Step 3: Implement deterministic digests and transactional copy**

```python
TABLE_ORDER = ("users", "characters", "parties", "party_members", "workouts", "setlogs", "body_stats", "reactions")

def row_digest(rows: Iterable[Mapping[str, Any]]) -> str:
    canonical = "\n".join(json.dumps(dict(row), sort_keys=True, default=str, separators=(",", ":")) for row in rows)
    return hashlib.sha256(canonical.encode()).hexdigest()
```

Temporarily defer the circular user/character link by copying users with `character_id=None`, copy characters, then update `users.character_id` inside the same target transaction. Reject a non-empty target and a target whose Alembic revision differs from `20260715_0001`.

- [ ] **Step 4: Repair PostgreSQL sequences and emit the manifest atomically**

For every integer primary key table call `setval(pg_get_serial_sequence(...), max(id), true)`. Write the JSON manifest only after the database transaction commits, using a temporary sibling file followed by atomic replace.

- [ ] **Step 5: Run transfer, rollback, and CLI tests**

Run: `python -m pytest backend/tests/test_sqlite_transfer.py -q`. Expected: PASS with matching counts/digests and no partial target rows.

- [ ] **Step 6: Commit**

```bash
git add backend/scripts/migrate_sqlite_to_postgres.py backend/tests/test_sqlite_transfer.py docs/operations/sqlite-cutover.md
git commit -m "feat(ELO-18): add verified SQLite cutover tooling"
```

### Task 4: Private object-storage boundary

**Files:**
- Create: `backend/storage.py`
- Create: `backend/tests/test_storage.py`
- Modify: `.env.example`
- Create: `docs/operations/object-storage.md`

**Interfaces:**
- Produces: `ObjectMetadata`, `StoragePolicy.validate(content_type: str, size_bytes: int) -> None`, `ObjectStorage.put(key, body, content_type)`, `head(key)`, `signed_get_url(key, expires_seconds=300)`, and `delete(key)`.
- Consumes: the storage fields from `Settings`.

- [ ] **Step 1: Write policy and fake-adapter tests**

```python
@pytest.mark.parametrize("content_type", ["text/html", "image/svg+xml", "application/octet-stream"])
def test_policy_rejects_unapproved_type(content_type):
    with pytest.raises(StoragePolicyError):
        StoragePolicy(max_bytes=10_000_000).validate(content_type, 1)

def test_signed_url_is_single_object_and_five_minutes(fake_storage):
    url = fake_storage.signed_get_url("users/1/abc.jpg")
    assert url.expires_seconds == 300
    assert url.key == "users/1/abc.jpg"
```

Also reject absolute paths, `..`, empty segments, leading slash, and objects over 10 MiB.

- [ ] **Step 2: Run tests and observe the missing module**

Run: `python -m pytest backend/tests/test_storage.py -q`. Expected: FAIL with missing `storage`.

- [ ] **Step 3: Implement the protocol, policy, memory fake, and S3 adapter**

Allow only `image/jpeg`, `image/png`, and `image/webp`. Configure boto3 with explicit endpoint/region/credentials, path-style addressing for MinIO, disabled public ACL usage, and generated opaque keys from `uuid4().hex`. Translate provider exceptions into `StorageUnavailable` without preserving provider response text.

- [ ] **Step 4: Prove bucket privacy in the local integration stack**

Use MinIO client policy inspection to assert anonymous `s3:GetObject` and `s3:ListBucket` are absent. Upload one object, fetch it through a 300-second signed URL, delete it, then assert `head` reports missing.

- [ ] **Step 5: Run storage tests**

Run: `python -m pytest backend/tests/test_storage.py -q`. Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add backend/storage.py backend/tests/test_storage.py .env.example docs/operations/object-storage.md
git commit -m "feat(ELO-18): add private object storage contract"
```

### Task 5: Readiness, correlation, JSON logs, metrics, and error tracking

**Files:**
- Create: `backend/observability.py`
- Create: `backend/tests/test_observability.py`
- Modify: `backend/main.py`
- Create: `ops/prometheus/alerts.yml`

**Interfaces:**
- Produces: `configure_observability(app, settings)`, `RequestContextMiddleware`, `/healthz`, `/readyz`, and internal `/metrics`.
- Consumes: `database.engine` and `Settings.release/app_env/sentry_dsn`.

- [ ] **Step 1: Add failing endpoint and redaction tests**

Assert health never queries the DB, readiness returns `{"status":"ready"}` on success and only `{"status":"unavailable"}` with 503 on failure, every response contains a UUID request ID, and serialized log events contain none of `authorization`, `cookie`, `email`, `body`, `filename`, or `signed_url`.

- [ ] **Step 2: Run tests and confirm endpoints/middleware are absent**

Run: `python -m pytest backend/tests/test_observability.py -q`. Expected: FAIL.

- [ ] **Step 3: Implement one completion event per request**

```python
request_id = inbound if REQUEST_ID_RE.fullmatch(inbound or "") else str(uuid.uuid4())
started = time.perf_counter()
response = await call_next(request)
response.headers["X-Request-ID"] = request_id
logger.info("http_request", request_id=request_id, route=route_template, status=response.status_code,
            latency_ms=round((time.perf_counter() - started) * 1000, 2))
```

Initialize Sentry only when a DSN exists; set environment/release and deny request bodies, cookies, and PII. Expose Prometheus request count/latency and readiness failure counters.

- [ ] **Step 4: Add alert rules**

Define exact alerts for readiness failure over 2 minutes, 5xx ratio over 5% for 5 minutes, p95 latency over 1 second for 10 minutes, and missing successful backup for 26 hours.

- [ ] **Step 5: Run focused tests**

Run: `python -m pytest backend/tests/test_observability.py -q`. Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add backend/observability.py backend/main.py backend/tests/test_observability.py ops/prometheus/alerts.yml
git commit -m "feat(ELO-18): add operational health and telemetry"
```

### Task 6: Immutable application image and production-like Compose stacks

**Files:**
- Create: `Dockerfile`
- Create: `.dockerignore`
- Create: `docker-compose.yml`
- Create: `compose.staging.yml`
- Create: `ops/Caddyfile`
- Create: `ops/entrypoint.sh`
- Modify: `backend/main.py`
- Modify: `frontend/vite.config.ts`
- Modify: `README.md`

**Interfaces:**
- Produces: image entrypoint that runs migrations then `uvicorn`, local services `db`, `object-storage`, `migrate`, `app`, and staging `edge`.
- Consumes: Tasks 1-5 and frontend `npm ci && npm run build`.

- [ ] **Step 1: Write a container smoke script**

The script builds the image, asserts its configured user is non-root, starts PostgreSQL/MinIO/migration/app, waits for `/readyz`, requests the SPA root and `/api/health`, and verifies `alembic current` equals `20260715_0001`.

- [ ] **Step 2: Build once and observe missing Dockerfile failure**

Run: `docker build --pull -t hell-setlog:elo18 .`. Expected: FAIL because `Dockerfile` is absent.

- [ ] **Step 3: Implement a multi-stage locked build**

Use `node:22-alpine` with `npm ci`, `python:3.12-slim` with `pip install --requirement`, a dedicated UID/GID 10001, read-only application files, and `PYTHONDONTWRITEBYTECODE=1`. Copy the frontend dist and add an SPA fallback after API routes.

- [ ] **Step 4: Add dependency-aware Compose stacks**

PostgreSQL and MinIO have health checks and private volumes. The migration service must finish successfully before the app starts. Staging accepts only `APP_IMAGE` by immutable digest, puts Caddy on ports 80/443, and reads secrets from the host/environment rather than committed values.

- [ ] **Step 5: Run the full container smoke**

Run: `docker compose up --build --wait`, then `python backend/scripts/smoke_api.py http://127.0.0.1:8000`. Expected: all services healthy and the smoke script exits 0. Finish with `docker compose down`.

- [ ] **Step 6: Commit**

```bash
git add Dockerfile .dockerignore docker-compose.yml compose.staging.yml ops/Caddyfile ops/entrypoint.sh backend/main.py frontend/vite.config.ts README.md
git commit -m "feat(ELO-18): build immutable production-like stack"
```

### Task 7: Automated backup, isolated restore rehearsal, and rollback runbook

**Files:**
- Create: `ops/backup.py`
- Create: `ops/restore_rehearsal.py`
- Create: `backend/tests/test_backup_commands.py`
- Create: `docs/operations/backup-restore.md`
- Create: `docs/operations/deploy-rollback.md`
- Modify: `docker-compose.yml`

**Interfaces:**
- Produces: `python ops/backup.py` and `python ops/restore_rehearsal.py --backup-key KEY`, each emitting one JSON result.
- Consumes: PostgreSQL CLI tools, private backup bucket/prefix, Alembic, and application smoke command.

- [ ] **Step 1: Write command-construction and redaction tests**

Assert `pg_dump --format=custom --no-owner --no-acl`, `pg_restore --clean --if-exists --no-owner --no-acl`, a new restore database name, and output JSON without credentials or full database URL. Mock a failed subprocess and assert non-zero exit plus `{"status":"failed"}`.

- [ ] **Step 2: Run tests and observe missing scripts**

Run: `python -m pytest backend/tests/test_backup_commands.py -q`. Expected: FAIL.

- [ ] **Step 3: Implement backup and restore rehearsal**

Backup writes to a restricted temporary directory, uploads to `backups/{environment}/{UTC timestamp}-{release}.dump`, verifies object size/checksum, then deletes the local file. Restore creates a new database, downloads one selected key, restores it, checks Alembic head, runs table-count verification and smoke, records elapsed seconds, and always removes the temporary file.

- [ ] **Step 4: Document exact cutover and rollback decisions**

The deploy runbook records image digest, revision, restore point, flags, owner, and rollback command. It states: previous image for app/config failure; forward-fix or feature flag for DB by default; downgrade only after the exact revision rehearsal; SQLite fallback only before PostgreSQL accepts post-cutover writes.

- [ ] **Step 5: Rehearse against the local stack**

Seed the local PostgreSQL service, run backup, restore into a new database, verify counts and smoke, then redeploy the prior local image digest. Expected: backup and restore JSON report `status=ok`, RTO elapsed time is recorded, and original DB remains untouched.

- [ ] **Step 6: Commit**

```bash
git add ops/backup.py ops/restore_rehearsal.py backend/tests/test_backup_commands.py docs/operations docker-compose.yml
git commit -m "feat(ELO-18): automate backup restore and rollback rehearsal"
```

### Task 8: Image promotion CI/CD and final evidence

**Files:**
- Create: `.github/workflows/operational-foundation.yml`
- Create: `.github/workflows/deploy-staging.yml`
- Create: `docs/operations/staging.md`
- Create: `docs/operations/evidence/ELO-18.md`

**Interfaces:**
- Produces: PR verification workflow, GHCR image digest, protected staging deployment using GitHub environment secrets, and an evidence record.
- Consumes: every earlier task.

- [ ] **Step 1: Add workflow static checks**

Use actionlint when available and parse both YAML files in a test. Assert every third-party action is pinned to a full commit SHA, permissions default to `contents: read`, package write permission is job-local, and staging uses an environment gate.

- [ ] **Step 2: Implement PR verification and immutable image publication**

Run backend tests, fresh migration, transfer test, frontend `npm ci && npm run build`, container build, local stack smoke, and backup/restore rehearsal. On master, push `ghcr.io/<owner>/hell-setlog` and export its digest. Do not embed cloud credentials.

- [ ] **Step 3: Implement staging deployment with explicit external inputs**

Require `STAGING_HOST`, `STAGING_USER`, `STAGING_SSH_KEY`, `STAGING_APP_HOST`, and server-side secret files from the protected `staging` GitHub environment. Deploy `APP_IMAGE=<digest> docker compose -f compose.staging.yml up -d --wait`, then verify HTTPS `/readyz` and the core smoke loop. On failure, invoke the documented previous-digest rollback command.

- [ ] **Step 4: Run the complete verification suite**

Run:
- `python -m pytest backend/tests -q`
- `npm --prefix frontend ci`
- `npm --prefix frontend run build`
- `alembic -c backend/alembic.ini upgrade head`
- `docker compose up --build --wait`
- `python backend/scripts/smoke_api.py http://127.0.0.1:8000`
- backup and isolated restore rehearsal
- `git diff --check`

Expected: every command exits 0. Record exact command, timestamp, revision, image digest, row counts, and restore elapsed time in the evidence document. If external staging secrets/host are unavailable, mark only the live HTTPS deployment evidence as blocked and do not claim a URL.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows docs/operations/staging.md docs/operations/evidence/ELO-18.md
git commit -m "ci(ELO-18): verify and promote operational foundation"
```
