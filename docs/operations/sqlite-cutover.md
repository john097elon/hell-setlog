# SQLite to PostgreSQL cutover

This runbook migrates one read-only Hell Setlog SQLite snapshot into an empty PostgreSQL database at Alembic revision `20260715_0001`. It never changes the source and refuses a non-empty target.

## Preconditions

- Announce the write freeze and stop every process that can change the SQLite file.
- Copy the SQLite database and record its SHA-256 checksum.
- Create a new PostgreSQL database with TLS and the migration role.
- Set `DATABASE_URL` to the target and run `alembic -c backend/alembic.ini upgrade head`.
- Confirm the target contains no application rows.

## Transfer and verification

Use URLs from the secret manager; do not paste credentials into tickets or shell history.

```powershell
.\.venv\Scripts\python.exe backend\scripts\migrate_sqlite_to_postgres.py --source-url "sqlite:///C:/secure/hellsetlog.snapshot.db" --target-url "$env:DATABASE_URL" --manifest ".\evidence\sqlite-transfer.manifest.json"
```

The command copies all rows in one target transaction, preserves identifiers, resolves the user/character circular reference, repairs PostgreSQL sequences, checks foreign keys, and compares per-table counts and deterministic row digests. The manifest contains counts and hashes, not row data or credentials.

Run a separate verification before cutover:

```powershell
.\.venv\Scripts\python.exe backend\scripts\migrate_sqlite_to_postgres.py --source-url "sqlite:///C:/secure/hellsetlog.snapshot.db" --target-url "$env:DATABASE_URL" --manifest ".\evidence\unused.json" --verify-only
```

A successful report has `"ok": true` and an empty `differences` object. Keep the source checksum, transfer manifest, Alembic revision, command exit code, operator, and time in the release evidence.

## Cutover

1. Start the candidate image against PostgreSQL while external traffic remains disabled.
2. Confirm `/readyz`, login, party list, workout history, and one synthetic create/end loop.
3. Compare the application row counts with the manifest.
4. Enable traffic and monitor readiness, 5xx rate, DB latency, and errors.
5. Keep the SQLite snapshot immutable until the recovery retention decision.

## Rollback

Before PostgreSQL accepts post-cutover writes, disable traffic and point the previous application image back to the immutable SQLite snapshot. Do not reverse-copy rows.

After PostgreSQL accepts writes, SQLite is no longer a valid rollback target. Disable risky features or redeploy the prior compatible image, then restore PostgreSQL to the recorded pre-migration restore point or forward-fix according to the incident decision. Never overwrite the live production database in place.
