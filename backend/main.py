"""Hell Setlog — FastAPI application entry point.

Run with:
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload
"""

import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from database import init_db

# ── Create the FastAPI app ──────────────────────────────────────────────────
app = FastAPI(
    title="Hell Setlog API",
    description="Social fitness app — join parties, share workout setlogs, grow your character.",
    version="0.1.0",
)

# ── CORS — allow frontend dev server ────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Static file serving for uploaded files ──────────────────────────────────
UPLOADS_DIR = os.path.join(os.path.dirname(__file__), "uploads")
os.makedirs(UPLOADS_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOADS_DIR), name="uploads")

# ── Mount all routers ───────────────────────────────────────────────────────
import auth  # noqa: E402
from routers.parties import router as parties_router  # noqa: E402
from routers.workouts import router as workouts_router  # noqa: E402
from routers.stats import router as stats_router  # noqa: E402
from routers.reactions import router as reactions_router  # noqa: E402
from routers.streak import router as streak_router  # noqa: E402
from routers.characters import router as characters_router  # noqa: E402
from routers.users import router as users_router  # noqa: E402

app.include_router(auth.router, prefix="/api")
app.include_router(parties_router, prefix="/api")
app.include_router(workouts_router, prefix="/api")
app.include_router(stats_router, prefix="/api")
app.include_router(reactions_router, prefix="/api")
app.include_router(streak_router, prefix="/api")
app.include_router(characters_router, prefix="/api")
app.include_router(users_router, prefix="/api")


# ── Health check ────────────────────────────────────────────────────────────
@app.get("/api/health")
def health():
    return {"status": "ok", "service": "hell-setlog"}


# ── Startup: create database tables ─────────────────────────────────────────
@app.on_event("startup")
def on_startup():
    init_db()


# ── Main guard for `python main.py` ─────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
