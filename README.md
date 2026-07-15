# Hell Setlog

Hell Setlog is a FastAPI and React PWA. The operational foundation uses PostgreSQL, Alembic, private S3-compatible objects, an immutable application image, and a same-origin frontend/API deployment.

## Local application process

Create a Python 3.12 environment, install `backend/requirements.txt`, install the frontend with `npm ci`, and run the database migration before starting the API.

```powershell
.\.venv\Scripts\python.exe -m pip install -r backend\requirements.txt
npm --prefix frontend ci
$env:PYTHONPATH = "backend"
.\.venv\Scripts\alembic.exe -c backend\alembic.ini upgrade head
.\.venv\Scripts\uvicorn.exe main:app --app-dir backend --reload
```

Run backend tests with:

```powershell
.\.venv\Scripts\python.exe -m pytest -p no:cacheprovider backend\tests -q
```

## Production-like local stack

Docker Compose builds the locked frontend and backend into one non-root image, starts PostgreSQL 16 and private MinIO storage, runs Alembic as a one-shot migration job, and starts the app only after migration succeeds.

```powershell
docker compose up --build --wait
python backend\scripts\smoke_api.py http://127.0.0.1:8000
docker compose down
```

- App and PWA: http://127.0.0.1:8000
- Liveness: http://127.0.0.1:8000/healthz
- Readiness: http://127.0.0.1:8000/readyz
- MinIO console: http://127.0.0.1:9001

The local credentials in `docker-compose.yml` are development-only. Staging and production fail closed unless their managed PostgreSQL, private storage, HTTPS origin/hosts, release, and error-tracking settings are supplied through the secret store.

See `docs/operations/sqlite-cutover.md`, `docs/operations/object-storage.md`, and the staging/backup/rollback runbooks for operator procedures.
