"""SQLAlchemy database models for Hell Setlog."""
from datetime import datetime, timezone

from sqlalchemy import (
    Column,
    Integer,
    String,
    Text,
    DateTime,
    ForeignKey,
    UniqueConstraint,
    CheckConstraint,
    Boolean,
)
from sqlalchemy.orm import relationship

from database import Base


def utcnow():
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    character_id = Column(
        Integer,
        ForeignKey("characters.id", use_alter=True, name="fk_user_character"),
        nullable=True,
        unique=True,
    )
    workout_tags = Column(String(500), nullable=True, default="[]")
    created_at = Column(DateTime, default=utcnow, nullable=False)

    # Relationships — separate, no back_populates due to circular FKs
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

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer, ForeignKey("users.id"), unique=True, nullable=False
    )
    name = Column(String(50), nullable=False)
    avatar_seed = Column(String(255), default="")
    created_at = Column(DateTime, default=utcnow, nullable=False)

    # Relationships
    user = relationship(
        "User",
        foreign_keys=[user_id],
        uselist=False,
    )
    body_stats = relationship("BodyStat", back_populates="character")


class Party(Base):
    __tablename__ = "parties"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    invite_code = Column(String(6), unique=True, nullable=False, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    match_type = Column(String(20), default="manual", nullable=False)
    max_members = Column(Integer, default=4, nullable=False)
    is_open = Column(Boolean, default=True, nullable=False)
    last_matched_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=utcnow, nullable=False)

    # Relationships
    owner = relationship("User", back_populates="owned_parties", foreign_keys=[owner_id])
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
    )

    id = Column(Integer, primary_key=True, index=True)
    party_id = Column(Integer, ForeignKey("parties.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    joined_at = Column(DateTime, default=utcnow, nullable=False)
    role = Column(String(20), default="member", nullable=False)
    status = Column(String(20), default="active", nullable=False)
    left_at = Column(DateTime, nullable=True)

    # Relationships
    party = relationship("Party", back_populates="members")
    user = relationship("User", back_populates="party_memberships")


class Workout(Base):
    __tablename__ = "workouts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    party_id = Column(Integer, ForeignKey("parties.id"), nullable=True)
    started_at = Column(DateTime, default=utcnow, nullable=False)
    ended_at = Column(DateTime, nullable=True)
    status = Column(String(20), default="active", nullable=False)
    notes = Column(Text, nullable=True)

    # Relationships
    user = relationship("User", back_populates="workouts")
    party = relationship("Party", back_populates="workouts")
    setlogs = relationship("Setlog", back_populates="workout")


class Setlog(Base):
    __tablename__ = "setlogs"
    __table_args__ = (
        CheckConstraint(
            "type IN ('start', 'mid', 'end')", name="ck_setlog_type"
        ),
    )

    id = Column(Integer, primary_key=True, index=True)
    workout_id = Column(Integer, ForeignKey("workouts.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    type = Column(String(10), nullable=False)
    content = Column(Text, nullable=False, default="")
    file_path = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=utcnow, nullable=False)

    # Relationships
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
    character_id = Column(Integer, ForeignKey("characters.id"), nullable=False)
    part = Column(String(20), nullable=False)
    level = Column(Integer, default=1, nullable=False)
    potential = Column(Integer, default=0, nullable=False)
    updated_at = Column(DateTime, default=utcnow, nullable=False)

    # Relationships
    character = relationship("Character", back_populates="body_stats")


class Reaction(Base):
    __tablename__ = "reactions"
    __table_args__ = (
        CheckConstraint(
            "target_type IN ('setlog', 'workout')", name="ck_reaction_target_type"
        ),
    )

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    target_type = Column(String(20), nullable=False)
    target_id = Column(Integer, nullable=False)
    emoji = Column(String(20), nullable=False)
    created_at = Column(DateTime, default=utcnow, nullable=False)

    # Relationships
    user = relationship("User", back_populates="reactions")
