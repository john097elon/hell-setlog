"""Add growth_events table for server-authoritative GrowthEvent engine.

Existing body_stats rows are preserved as-is (level/potential intact).
New GrowthEvent records are written from this point forward.

Revision ID: 20260715_0002
Revises: 20260715_0001
Create Date: 2026-07-15
"""

from typing import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "20260715_0002"
down_revision: str | None = "20260715_0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "growth_events",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("workout_id", sa.Integer(), nullable=False),
        sa.Column("body_part", sa.String(length=20), nullable=False),
        sa.Column("delta", sa.Integer(), nullable=False),
        sa.Column("reason", sa.String(length=200), nullable=False),
        sa.Column("formula_version", sa.Integer(), nullable=False),
        sa.Column("level_before", sa.Integer(), nullable=False),
        sa.Column("potential_before", sa.Integer(), nullable=False),
        sa.Column("level_after", sa.Integer(), nullable=False),
        sa.Column("potential_after", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["user_id"], ["users.id"], name="fk_growth_events_user"
        ),
        sa.ForeignKeyConstraint(
            ["workout_id"], ["workouts.id"], name="fk_growth_events_workout"
        ),
        sa.UniqueConstraint(
            "workout_id", "body_part", name="uq_growth_event_workout_part"
        ),
        sa.CheckConstraint(
            "body_part IN ('chest', 'back', 'legs', 'shoulders', 'arms', 'core', 'stamina')",
            name="ck_growth_event_body_part",
        ),
    )
    op.create_index(
        "ix_growth_events_user_created_at",
        "growth_events",
        ["user_id", "created_at"],
        unique=False,
    )
    op.create_index(
        "ix_growth_events_workout",
        "growth_events",
        ["workout_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_growth_events_workout", table_name="growth_events")
    op.drop_index("ix_growth_events_user_created_at", table_name="growth_events")
    op.drop_table("growth_events")
