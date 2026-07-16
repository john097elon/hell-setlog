"""Authentication: JWT creation/verification, password hashing, get_current_user dependency."""

import os
import time
from collections import defaultdict
from datetime import datetime, timedelta, timezone

import bcrypt
from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from database import get_db
from models import BodyStat, Character, User
from schemas import (
    CharacterOut,
    LoginRequest,
    RegisterRequest,
    TokenResponse,
    UserMeOut,
    UserOut,
)

# ── Config ──────────────────────────────────────────────────────────────────
_DEV_SECRET = "dev-secret-hellsetlog-change-in-production"
_ENV = os.getenv("ENV", "dev")
SECRET_KEY = os.getenv("SECRET_KEY", _DEV_SECRET)
if _ENV != "dev" and SECRET_KEY == _DEV_SECRET:
    raise RuntimeError(
        "SECRET_KEY must be set to a strong random value in non-dev environments"
    )

JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 days

security = HTTPBearer(auto_error=False)

# ── Simple in-memory rate limiter ────────────────────────────────────────────
_rate_buckets: dict[str, list[float]] = defaultdict(list)
_RATE_WINDOW = 60  # seconds


def _check_rate_limit(key: str, max_attempts: int) -> None:
    if os.getenv("DISABLE_RATE_LIMIT") == "1":
        return
    now = time.monotonic()
    bucket = _rate_buckets[key]
    bucket[:] = [t for t in bucket if now - t < _RATE_WINDOW]
    if len(bucket) >= max_attempts:
        raise HTTPException(
            status_code=429, detail="Too many requests, try again later"
        )
    bucket.append(now)


router = APIRouter(prefix="/auth", tags=["auth"])

# The 7 BodyStat parts per the spec
BODY_PARTS = ["chest", "back", "legs", "shoulders", "arms", "core", "stamina"]


# ── Helper functions ────────────────────────────────────────────────────────


def hash_password(password: str) -> str:
    """Hash a plaintext password with bcrypt."""
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plaintext password against a bcrypt hash."""
    return bcrypt.checkpw(
        plain_password.encode("utf-8"), hashed_password.encode("utf-8")
    )


def create_access_token(user_id: int) -> str:
    """Create a JWT access token for the given user ID."""
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "iat": now,
        "exp": now + timedelta(minutes=TOKEN_EXPIRE_MINUTES),
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=JWT_ALGORITHM)


def decode_access_token(token: str) -> dict:
    """Decode and validate a JWT. Raises JWTError on failure."""
    return jwt.decode(token, SECRET_KEY, algorithms=[JWT_ALGORITHM])


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
    db: Session = Depends(get_db),
) -> User:
    """FastAPI dependency: extract and validate the JWT, return the User."""
    if credentials is None:
        raise HTTPException(status_code=401, detail="Not authenticated")

    token = credentials.credentials
    try:
        payload = decode_access_token(token)
        user_id: str | None = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

    user = db.query(User).filter(User.id == int(user_id)).first()
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")
    return user


def _build_avatar_url(avatar_seed: str | None) -> str | None:
    """Build a self-hosted avatar URL from the character's avatar_seed."""
    if not avatar_seed:
        return None
    stage_num = 1
    parts = [p.strip() for p in avatar_seed.split(",") if p.strip()]
    for part in parts:
        if part.startswith("stage_"):
            try:
                stage_num = int(part.split("_")[1])
            except (ValueError, IndexError):
                pass
    from settings import get_settings

    try:
        settings = get_settings()
        cdn_url = settings.asset_cdn_url
        version = settings.asset_version
    except Exception:
        cdn_url = None
        version = "v2"
    path = f"/assets/avatars/stage_{stage_num}.svg"
    url = f"{path}?v={version}"
    if cdn_url:
        base = cdn_url.rstrip("/")
        url = f"{base}{url}"
    return url


# ── Endpoints ───────────────────────────────────────────────────────────────


@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def register(request: Request, body: RegisterRequest, db: Session = Depends(get_db)):
    """Register a new user, creating character + 7 BodyStats."""
    _check_rate_limit(f"register:{request.client.host}", max_attempts=10)
    # Generic conflict response prevents username/email enumeration
    username_taken = db.query(User).filter(User.username == body.username).first()
    email_taken = db.query(User).filter(User.email == body.email).first()
    if username_taken or email_taken:
        raise HTTPException(
            status_code=409, detail="Unable to create account with provided credentials"
        )

    # 1. Create user with character_id=NULL (will backfill after character creation)
    user = User(
        username=body.username,
        email=body.email,
        password_hash=hash_password(body.password),
        character_id=None,
    )
    db.add(user)
    db.flush()

    # 2. Create character
    character = Character(
        user_id=user.id,
        name=body.username,
        avatar_seed="default",
    )
    db.add(character)
    db.flush()

    # 3. Link user -> character (close circular FK)
    user.character_id = character.id
    db.flush()

    # 4. Create all 7 BodyStat entries
    now = datetime.now(timezone.utc)
    for part in BODY_PARTS:
        db.add(
            BodyStat(
                character_id=character.id,
                part=part,
                level=1,
                potential=0,
                updated_at=now,
            )
        )

    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=TokenResponse)
def login(request: Request, body: LoginRequest, db: Session = Depends(get_db)):
    """Authenticate and return a JWT access token."""
    _check_rate_limit(f"login:{request.client.host}", max_attempts=20)
    if body.username:
        user = db.query(User).filter(User.username == body.username).first()
    elif body.email:
        user = db.query(User).filter(User.email == body.email).first()
    else:
        raise HTTPException(status_code=422, detail="Username or email is required")
    # Generic error prevents username/email enumeration
    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_access_token(user.id)
    return TokenResponse(
        access_token=token,
        user_id=user.id,
        username=user.username,
    )


@router.get("/me", response_model=UserMeOut)
def me(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Return the currently authenticated user's profile with avatar URL."""
    db.refresh(current_user, attribute_names=["character"])
    if current_user.character:
        db.refresh(current_user.character, attribute_names=["body_stats"])

    # Build the response manually to include avatar_url
    char_out = None
    avatar_url = None
    if current_user.character:
        char_out = CharacterOut.model_validate(current_user.character)
        avatar_url = current_user.character.avatar_url

    return UserMeOut(
        id=current_user.id,
        username=current_user.username,
        email=current_user.email,
        character=char_out,
        avatar_url=avatar_url,
        workout_tags=current_user.workout_tags or "[]",
        created_at=current_user.created_at,
    )
