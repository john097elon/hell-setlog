"""Pydantic schemas for Hell Setlog request/response validation."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field

# ── Auth ────────────────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    username: str = Field(..., min_length=2, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=6)


class LoginRequest(BaseModel):
    username: str | None = None
    email: EmailStr | None = None
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    username: str | None = None


# ── BodyStat ────────────────────────────────────────────────────────────────

class BodyStatOut(BaseModel):
    id: int
    part: str
    level: int
    potential: int
    updated_at: datetime

    model_config = {"from_attributes": True}


class BodyStatUpdate(BaseModel):
    level: Optional[int] = None
    potential: Optional[int] = None


# ── Character ───────────────────────────────────────────────────────────────

class CharacterOut(BaseModel):
    id: int
    user_id: int
    name: str
    avatar_seed: str
    created_at: datetime
    body_stats: list[BodyStatOut] = []

    model_config = {"from_attributes": True}


class CharacterUpdate(BaseModel):
    name: Optional[str] = None
    avatar_seed: Optional[str] = None


# ── User ────────────────────────────────────────────────────────────────────

class UserOut(BaseModel):
    id: int
    username: str | None = None
    email: str
    character_id: Optional[int] = None
    created_at: datetime
    character: Optional[CharacterOut] = None

    model_config = {"from_attributes": True}


class UserPublic(BaseModel):
    id: int
    username: str | None = None
    character: Optional[CharacterOut] = None

    model_config = {"from_attributes": True}


# ── Party / PartyMember ─────────────────────────────────────────────────────

class PartyCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)


class PartyJoin(BaseModel):
    invite_code: str = Field(..., min_length=6, max_length=6)


class PartyMemberOut(BaseModel):
    id: int
    user_id: int
    party_id: int
    joined_at: datetime
    role: str = "member"
    status: str = "active"
    left_at: Optional[datetime] = None
    user: Optional[UserPublic] = None

    model_config = {"from_attributes": True}


class PartyOut(BaseModel):
    id: int
    name: str
    invite_code: str
    owner_id: int
    match_type: str = "manual"
    max_members: int = 4
    is_open: bool = True
    last_matched_at: Optional[datetime] = None
    created_at: datetime
    owner: Optional[UserPublic] = None
    members: list[PartyMemberOut] = []
    member_count: int = 0

    model_config = {"from_attributes": True}


# ── Workout ─────────────────────────────────────────────────────────────────

class WorkoutCreate(BaseModel):
    party_id: Optional[int] = None
    notes: Optional[str] = None


class WorkoutUpdate(BaseModel):
    status: Optional[str] = None  # 'active' or 'done'
    ended_at: Optional[datetime] = None
    notes: Optional[str] = None


class WorkoutOut(BaseModel):
    id: int
    user_id: int
    party_id: Optional[int] = None
    started_at: datetime
    ended_at: Optional[datetime] = None
    status: str
    notes: Optional[str] = None
    user: Optional[UserPublic] = None
    setlogs: list["SetlogOut"] = []

    model_config = {"from_attributes": True}


# ── Setlog ──────────────────────────────────────────────────────────────────

class SetlogCreate(BaseModel):
    type: str = Field(..., pattern="^(start|mid|end)$")
    content: str = Field(..., min_length=1)
    file_path: Optional[str] = None


class SetlogOut(BaseModel):
    id: int
    workout_id: int
    user_id: int
    type: str
    content: str
    file_path: Optional[str] = None
    created_at: datetime
    user: Optional[UserPublic] = None
    reactions: list["ReactionOut"] = []

    model_config = {"from_attributes": True}


# ── Reaction ────────────────────────────────────────────────────────────────
# ── Reaction ────────────────────────────────────────────────────────────────

class ReactionCreate(BaseModel):
    target_type: str = Field(..., pattern="^(setlog|workout)$")
    target_id: int
    emoji: str = Field(..., min_length=1, max_length=20)

class ReactionOut(BaseModel):
    id: int
    user_id: int
    target_type: str
    target_id: int
    emoji: str
    created_at: datetime
    user: Optional[UserPublic] = None

    model_config = {"from_attributes": True}


# ── Party Feed ──────────────────────────────────────────────────────────────

class FeedEventData(BaseModel):
    """Union-typed payload — contains only the keys relevant to the event_type."""
    # setlog event fields
    setlog_id: Optional[int] = None
    type: Optional[str] = None
    content: Optional[str] = None
    file_path: Optional[str] = None
    workout_id: Optional[int] = None
    # workout_start / workout_end event fields
    notes: Optional[str] = None
    duration_seconds: Optional[int] = None
    setlog_count: Optional[int] = None
    # member_joined event fields
    # (user_id/username are in the outer user dict, but we include for clarity)
    # reaction event fields
    reaction_id: Optional[int] = None
    target_type: Optional[str] = None
    target_id: Optional[int] = None
    emoji: Optional[str] = None


class FeedWorkoutStats(BaseModel):
    duration_seconds: Optional[int] = None
    setlog_count: Optional[int] = None


class FeedEvent(BaseModel):
    id: str
    event_type: str
    created_at: datetime
    user: Optional[UserPublic] = None
    username: Optional[str] = None
    content: Optional[str] = None
    setlog_type: Optional[str] = None
    file_path: Optional[str] = None
    workout_id: Optional[int] = None
    setlog_id: Optional[int] = None
    target_type: Optional[str] = None
    target_id: Optional[int] = None
    reaction_type: Optional[str] = None
    workout_stats: Optional[FeedWorkoutStats] = None
    breakthroughs: list["Breakthrough"] = []
    body_stats: list["BodyStatSummary"] = []
    data: FeedEventData = FeedEventData()


# ── Workout End ─────────────────────────────────────────────────────────────

class Breakthrough(BaseModel):
    part: str
    old_level: Optional[int] = None
    new_level: int


class BodyStatSummary(BaseModel):
    part: str
    level: int
    potential: int


class WorkoutEndResponse(BaseModel):
    workout: WorkoutOut
    breakthroughs: list[Breakthrough] = []
    all_stats: list[BodyStatSummary] = []


# ── Auth Me (with avatar) ──────────────────────────────────────────────────

class WorkoutTagsUpdate(BaseModel):
    workout_tags: str


class UserMeOut(BaseModel):
    id: int
    username: str | None = None
    email: str
    character_id: Optional[int] = None
    workout_tags: str = "[]"
    created_at: datetime
    character: Optional[CharacterOut] = None
    avatar_url: Optional[str] = None

    model_config = {"from_attributes": True}


# ── Rebuild forward references ──────────────────────────────────────────────
WorkoutOut.model_rebuild()
SetlogOut.model_rebuild()
