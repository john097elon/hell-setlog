"""Create the Hell Setlog relational baseline.

Revision ID: 20260715_0001
Revises:
Create Date: 2026-07-15
"""

from typing import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "20260715_0001"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("username", sa.String(length=50), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("password_hash", sa.String(length=255), nullable=False),
        sa.Column("character_id", sa.Integer(), nullable=True),
        sa.Column("workout_tags", sa.String(length=500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("character_id", name="uq_users_character_id"),
    )
    op.create_index("ix_users_username", "users", ["username"], unique=True)
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.create_table(
        "characters",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=50), nullable=False),
        sa.Column("avatar_seed", sa.String(length=255), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], name="fk_characters_user"),
        sa.UniqueConstraint("user_id", name="uq_characters_user_id"),
    )
    with op.batch_alter_table("users") as batch_op:
        batch_op.create_foreign_key(
            "fk_user_character", "characters", ["character_id"], ["id"]
        )

    op.create_table(
        "parties",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("invite_code", sa.String(length=6), nullable=False),
        sa.Column("owner_id", sa.Integer(), nullable=False),
        sa.Column("match_type", sa.String(length=20), nullable=False),
        sa.Column("max_members", sa.Integer(), nullable=False),
        sa.Column("is_open", sa.Boolean(), nullable=False),
        sa.Column("last_matched_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["owner_id"], ["users.id"], name="fk_parties_owner"),
        sa.CheckConstraint("max_members > 0", name="ck_parties_max_members_positive"),
    )
    op.create_index("ix_parties_invite_code", "parties", ["invite_code"], unique=True)

    op.create_table(
        "party_members",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("party_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("joined_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("role", sa.String(length=20), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("left_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["party_id"], ["parties.id"], name="fk_party_members_party"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], name="fk_party_members_user"),
        sa.UniqueConstraint("party_id", "user_id", name="uq_party_member"),
        sa.CheckConstraint("role IN ('owner', 'member')", name="ck_party_member_role"),
        sa.CheckConstraint(
            "status IN ('active', 'left', 'kicked')", name="ck_party_member_status"
        ),
    )
    op.create_index(
        "ix_party_members_party_status",
        "party_members",
        ["party_id", "status"],
        unique=False,
    )

    op.create_table(
        "workouts",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("party_id", sa.Integer(), nullable=True),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], name="fk_workouts_user"),
        sa.ForeignKeyConstraint(["party_id"], ["parties.id"], name="fk_workouts_party"),
        sa.CheckConstraint(
            "status IN ('active', 'ended', 'done', 'cancelled')",
            name="ck_workouts_status",
        ),
    )
    op.create_index(
        "ix_workouts_user_started_at",
        "workouts",
        ["user_id", "started_at"],
        unique=False,
    )
    op.create_index(
        "ix_workouts_party_started_at",
        "workouts",
        ["party_id", "started_at"],
        unique=False,
    )

    op.create_table(
        "setlogs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("workout_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("type", sa.String(length=10), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("file_path", sa.String(length=500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["workout_id"], ["workouts.id"], name="fk_setlogs_workout"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], name="fk_setlogs_user"),
        sa.CheckConstraint("type IN ('start', 'mid', 'end')", name="ck_setlog_type"),
    )
    op.create_index(
        "ix_setlogs_workout_created_at",
        "setlogs",
        ["workout_id", "created_at"],
        unique=False,
    )

    op.create_table(
        "body_stats",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("character_id", sa.Integer(), nullable=False),
        sa.Column("part", sa.String(length=20), nullable=False),
        sa.Column("level", sa.Integer(), nullable=False),
        sa.Column("potential", sa.Integer(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["character_id"], ["characters.id"], name="fk_body_stats_character"
        ),
        sa.UniqueConstraint("character_id", "part", name="uq_body_stat"),
        sa.CheckConstraint(
            "part IN ('chest', 'back', 'legs', 'shoulders', 'arms', 'core', 'stamina')",
            name="ck_body_stat_part",
        ),
    )

    op.create_table(
        "reactions",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("target_type", sa.String(length=20), nullable=False),
        sa.Column("target_id", sa.Integer(), nullable=False),
        sa.Column("emoji", sa.String(length=20), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], name="fk_reactions_user"),
        sa.CheckConstraint(
            "target_type IN ('setlog', 'workout')",
            name="ck_reaction_target_type",
        ),
    )
    op.create_index(
        "ix_reactions_target",
        "reactions",
        ["target_type", "target_id", "created_at"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_table("reactions")
    op.drop_table("body_stats")
    op.drop_table("setlogs")
    op.drop_table("workouts")
    op.drop_table("party_members")
    op.drop_table("parties")
    with op.batch_alter_table("users") as batch_op:
        batch_op.drop_constraint("fk_user_character", type_="foreignkey")
    op.drop_table("characters")
    op.drop_table("users")
