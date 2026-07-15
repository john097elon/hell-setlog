"""Hell Setlog FastAPI application entry point."""

import os
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import engine
from observability import configure_observability
from settings import get_settings
from static_frontend import mount_frontend_if_present

# ── CORS config — explicit origins required in non-dev environments ──────────
_ENV = os.getenv("ENV", "dev")
_allowed_origins_raw = os.getenv("ALLOWED_ORIGINS", "")
if _allowed_origins_raw:
    _allowed_origins = [o.strip() for o in _allowed_origins_raw.split(",") if o.strip()]
elif _ENV == "dev":
    _allowed_origins = ["*"]
else:
    raise RuntimeError(
        "ALLOWED_ORIGINS must be set to a comma-separated list of HTTPS origins in non-dev environments"
    )

settings = get_settings()
app = FastAPI(
    title="Hell Setlog API",
    description=(
        "Social fitness app - join parties, share workout setlogs, "
        "and grow your character."
    ),
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=_allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization", "X-CSRF-Token"],
)
configure_observability(app, settings, engine)


import auth  # noqa: E402
from routers.characters import router as characters_router  # noqa: E402
from routers.parties import router as parties_router  # noqa: E402
from routers.reactions import router as reactions_router  # noqa: E402
from routers.stats import router as stats_router  # noqa: E402
from routers.streak import router as streak_router  # noqa: E402
from routers.users import router as users_router  # noqa: E402
from routers.workouts import router as workouts_router  # noqa: E402

app.include_router(auth.router, prefix="/api")
app.include_router(parties_router, prefix="/api")
app.include_router(workouts_router, prefix="/api")
app.include_router(stats_router, prefix="/api")
app.include_router(reactions_router, prefix="/api")
app.include_router(streak_router, prefix="/api")
app.include_router(characters_router, prefix="/api")
app.include_router(users_router, prefix="/api")


@app.get("/api/health")
def health():
    return {"status": "ok", "service": "hell-setlog"}


default_frontend = Path(__file__).resolve().parents[1] / "frontend" / "dist"
frontend_directory = Path(os.getenv("FRONTEND_DIST", str(default_frontend)))
mount_frontend_if_present(app, frontend_directory)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
