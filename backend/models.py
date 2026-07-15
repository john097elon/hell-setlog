"""SQLAlchemy database models for Hell Setlog."""

from datetime import datetime, timezone

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Column,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from database import Base


def utcnow():
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"
    __table_args__ = (UniqueConstraint("character_id", name="uq_users_character_id"),)

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    character_id = Column(
        Integer,
        ForeignKey("characters.id", use_alter=True, name="fk_user_character"),
        nullable=True,
    )
    workout_tags = Column(String(500), nullable=True, default="[]")
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)

    character = relationship(
        "Character",
        foreign_keys=[character_id],
        post_update=True,
        uselist=False,
    )
    owned_parties = relationship(
        "Party", back_populates="owner", foreign_keys="Party.owner_id"
    )
    party_memberships = relationship("PartyMember", back_populates="user")
    workouts = relationship("Workout", back_populates="user")
    setlogs = relationship("Setlog", back_populates="user")
    reactions = relationship("Reaction", back_populates="user")


class Character(Base):
    __tablename__ = "characters"
    __table_args__ = (UniqueConstraint("user_id", name="uq_characters_user_id"),)

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer,
        ForeignKey("users.id", name="fk_characters_user"),
        nullable=False,
    )
    name = Column(String(50), nullable=False)
    avatar_seed = Column(String(255), default="")
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)

    user = relationship(
        "User",
        foreign_keys=[user_id],
        uselist=False,
    )
    body_stats = relationship("BodyStat", back_populates="character")

    @property
    def parsed_seed_data(self) -> dict:
        # Format: "stage_X,cosmetic1,cosmetic2"
        seed_str = self.avatar_seed or ""
        parts = [p.strip() for p in seed_str.split(",") if p.strip()]
        stage_override = None
        cosmetics = []
        for part in parts:
            if part.startswith("stage_"):
                try:
                    stage_override = int(part.split("_")[1])
                except (ValueError, IndexError):
                    pass
            elif part not in {"default"}:
                cosmetics.append(part)
        return {"stage_override": stage_override, "cosmetics": cosmetics}

    @property
    def stage(self) -> int:
        override = self.parsed_seed_data["stage_override"]
        stage_num = 1
        if override is not None:
            stage_num = override
        elif self.body_stats:
            total_level = sum(bs.level for bs in self.body_stats)
            if total_level < 15:
                stage_num = 1
            elif total_level < 30:
                stage_num = 2
            else:
                stage_num = 3
        return max(1, min(3, stage_num))

    @property
    def cosmetics(self) -> list[str]:
        return self.parsed_seed_data["cosmetics"]

    @property
    def fallback_key(self) -> str:
        return self.name[0].upper() if self.name else "?"

    @property
    def asset_version(self) -> str:
        from settings import get_settings

        try:
            return get_settings().asset_version
        except Exception:
            return "v2"

    @property
    def avatar_url(self) -> str:
        from settings import get_settings

        try:
            settings = get_settings()
            cdn_url = settings.asset_cdn_url
            version = settings.asset_version
        except Exception:
            cdn_url = None
            version = "v2"
        stage_num = self.stage
        path = f"/assets/avatars/stage_{stage_num}.svg"
        url = f"{path}?v={version}"
        if cdn_url:
            base = cdn_url.rstrip("/")
            url = f"{base}{url}"
        return url


class Party(Base):
    __tablename__ = "parties"
    __table_args__ = (
        CheckConstraint("max_members > 0", name="ck_parties_max_members_positive"),
    )

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    invite_code = Column(String(6), unique=True, nullable=False, index=True)
    owner_id = Column(
        Integer,
        ForeignKey("users.id", name="fk_parties_owner"),
        nullable=False,
    )
    match_type = Column(String(20), default="manual", nullable=False)
    max_members = Column(Integer, default=4, nullable=False)
    is_open = Column(Boolean, default=True, nullable=False)
    last_matched_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)

    owner = relationship(
        "User", back_populates="owned_parties", foreign_keys=[owner_id]
    )
    members = relationship(
        "PartyMember",
        primaryjoin="and_(Party.id == PartyMember.party_id, PartyMember.status == 'active')",
        back_populates="party",
    )
    all_members = relationship(
        "PartyMember",
        primaryjoin="Party.id == PartyMember.party_id",
        viewonly=True,
    )
    workouts = relationship("Workout", back_populates="party")

    @property
    def member_count(self):
        return len(self.members or [])


class PartyMember(Base):
    __tablename__ = "party_members"
    __table_args__ = (
        UniqueConstraint("party_id", "user_id", name="uq_party_member"),
        CheckConstraint("role IN ('owner', 'member')", name="ck_party_member_role"),
        CheckConstraint(
            "status IN ('active', 'left', 'kicked')",
            name="ck_party_member_status",
        ),
        Index("ix_party_members_party_status", "party_id", "status"),
    )

    id = Column(Integer, primary_key=True, index=True)
    party_id = Column(
        Integer,
        ForeignKey("parties.id", name="fk_party_members_party"),
        nullable=False,
    )
    user_id = Column(
        Integer,
        ForeignKey("users.id", name="fk_party_members_user"),
        nullable=False,
    )
    joined_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    role = Column(String(20), default="member", nullable=False)
    status = Column(String(20), default="active", nullable=False)
    left_at = Column(DateTime(timezone=True), nullable=True)

    party = relationship("Party", back_populates="members")
    user = relationship("User", back_populates="party_memberships")


class Workout(Base):
    __tablename__ = "workouts"
    __table_args__ = (
        CheckConstraint(
            "status IN ('active', 'ended', 'done', 'cancelled')",
            name="ck_workouts_status",
        ),
        Index("ix_workouts_user_started_at", "user_id", "started_at"),
        Index("ix_workouts_party_started_at", "party_id", "started_at"),
    )

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer,
        ForeignKey("users.id", name="fk_workouts_user"),
        nullable=False,
    )
    party_id = Column(
        Integer,
        ForeignKey("parties.id", name="fk_workouts_party"),
        nullable=True,
    )
    started_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)
    ended_at = Column(DateTime(timezone=True), nullable=True)
    status = Column(String(20), default="active", nullable=False)
    notes = Column(Text, nullable=True)

    user = relationship("User", back_populates="workouts")
    party = relationship("Party", back_populates="workouts")
    setlogs = relationship("Setlog", back_populates="workout")


class Setlog(Base):
    __tablename__ = "setlogs"
    __table_args__ = (
        CheckConstraint(
            "type IN ('start', 'mid', 'end')",
            name="ck_setlog_type",
        ),
        Index("ix_setlogs_workout_created_at", "workout_id", "created_at"),
    )

    id = Column(Integer, primary_key=True, index=True)
    workout_id = Column(
        Integer,
        ForeignKey("workouts.id", name="fk_setlogs_workout"),
        nullable=False,
    )
    user_id = Column(
        Integer,
        ForeignKey("users.id", name="fk_setlogs_user"),
        nullable=False,
    )
    type = Column(String(10), nullable=False)
    content = Column(Text, nullable=False, default="")
    file_path = Column(String(500), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)

    workout = relationship("Workout", back_populates="setlogs")
    user = relationship("User", back_populates="setlogs")


class BodyStat(Base):
    __tablename__ = "body_stats"
    __table_args__ = (
        UniqueConstraint("character_id", "part", name="uq_body_stat"),
        CheckConstraint(
            "part IN ('chest', 'back', 'legs', 'shoulders', 'arms', 'core', 'stamina')",
            name="ck_body_stat_part",
        ),
    )

    id = Column(Integer, primary_key=True, index=True)
    character_id = Column(
        Integer,
        ForeignKey("characters.id", name="fk_body_stats_character"),
        nullable=False,
    )
    part = Column(String(20), nullable=False)
    level = Column(Integer, default=1, nullable=False)
    potential = Column(Integer, default=0, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)

    character = relationship("Character", back_populates="body_stats")


class GrowthEvent(Base):
    __tablename__ = "growth_events"
    __table_args__ = (
        UniqueConstraint(
            "workout_id", "body_part", name="uq_growth_event_workout_part"
        ),
        CheckConstraint(
            "body_part IN ('chest', 'back', 'legs', 'shoulders', 'arms', 'core', 'stamina')",
            name="ck_growth_event_body_part",
        ),
        Index("ix_growth_events_user_created_at", "user_id", "created_at"),
        Index("ix_growth_events_workout", "workout_id"),
    )

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer,
        ForeignKey("users.id", name="fk_growth_events_user"),
        nullable=False,
    )
    workout_id = Column(
        Integer,
        ForeignKey("workouts.id", name="fk_growth_events_workout"),
        nullable=False,
    )
    body_part = Column(String(20), nullable=False)
    delta = Column(Integer, nullable=False)
    reason = Column(String(200), nullable=False)
    formula_version = Column(Integer, nullable=False, default=1)
    level_before = Column(Integer, nullable=False)
    potential_before = Column(Integer, nullable=False)
    level_after = Column(Integer, nullable=False)
    potential_after = Column(Integer, nullable=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)

    user = relationship("User", foreign_keys=[user_id])
    workout = relationship("Workout", foreign_keys=[workout_id])


class Reaction(Base):
    __tablename__ = "reactions"
    __table_args__ = (
        CheckConstraint(
            "target_type IN ('setlog', 'workout')",
            name="ck_reaction_target_type",
        ),
        Index("ix_reactions_target", "target_type", "target_id", "created_at"),
    )

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer,
        ForeignKey("users.id", name="fk_reactions_user"),
        nullable=False,
    )
    target_type = Column(String(20), nullable=False)
    target_id = Column(Integer, nullable=False)
    emoji = Column(String(20), nullable=False)
    created_at = Column(DateTime(timezone=True), default=utcnow, nullable=False)

    user = relationship("User", back_populates="reactions")
