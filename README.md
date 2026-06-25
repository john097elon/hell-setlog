# Hell Setlog MVP dev notes

## Backend

1. Create and activate a virtual environment.
2. Install backend dependencies.
3. Start FastAPI on port 8000.

Commands:

    cd backend
    python3 -m venv .venv
    source .venv/bin/activate
    python -m pip install -r requirements.txt
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload

The backend stores SQLite data under backend/data/hellsetlog.db and serves uploaded files from backend/uploads/.

Health check:

    curl http://127.0.0.1:8000/api/health

### Backend smoke test

With the backend running, exercise registration, login, auth me, party creation, and workout creation:

    source backend/.venv/bin/activate
    python backend/scripts/smoke_api.py

Pass a custom base URL if needed:

    python backend/scripts/smoke_api.py http://127.0.0.1:8000

Note: Debian/Ubuntu WSL images may need python3-venv installed before python3 -m venv works. If pip/venv are unavailable, uv also works:

    export PATH="$HOME/.local/bin:$PATH"
    cd backend
    uv venv .venv
    source .venv/bin/activate
    uv pip install -r requirements.txt

✅ Tested by JARVIS pipeline — 2026-06-20.
