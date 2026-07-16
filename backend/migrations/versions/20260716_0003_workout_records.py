"""Add immutable structured workout records and exercise catalog.

Revision ID: 20260716_0003
Revises: 20260715_0002
Create Date: 2026-07-16
"""

from typing import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "20260716_0003"
down_revision: str | None = "20260715_0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

BODY_PARTS = ("chest", "back", "legs", "shoulders", "arms", "core", "stamina")


def upgrade() -> None:
    op.create_table(
        "exercises",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("canonical_name", sa.String(length=100), nullable=False),
        sa.Column("display_name_kr", sa.String(length=100), nullable=False),
        sa.Column("unit_kind", sa.String(length=20), nullable=False),
        sa.Column("body_part", sa.String(length=20), nullable=False),
        sa.UniqueConstraint("canonical_name", name="uq_exercise_canonical_name"),
        sa.CheckConstraint("unit_kind IN ('reps_weight', 'time', 'distance')", name="ck_exercise_unit_kind"),
        sa.CheckConstraint(
            "body_part IN ('chest', 'back', 'legs', 'shoulders', 'arms', 'core', 'stamina')",
            name="ck_exercise_body_part",
        ),
    )
    op.create_table(
        "workout_records",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("workout_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("exercise_id", sa.Integer(), nullable=False),
        sa.Column("performed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("idempotency_key", sa.String(length=100), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["workout_id"], ["workouts.id"], name="fk_workout_records_workout"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], name="fk_workout_records_user"),
        sa.ForeignKeyConstraint(["exercise_id"], ["exercises.id"], name="fk_workout_records_exercise"),
        sa.UniqueConstraint("user_id", "idempotency_key", name="uq_workout_record_idempotency"),
        sa.CheckConstraint("status = 'submitted'", name="ck_workout_record_status"),
    )
    op.create_index("ix_workout_records_user_performed_at", "workout_records", ["user_id", "performed_at"], unique=False)
    op.create_table(
        "exercise_sets",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("workout_record_id", sa.Integer(), nullable=False),
        sa.Column("set_index", sa.Integer(), nullable=False),
        sa.Column("reps", sa.Integer(), nullable=True),
        sa.Column("weight_kg", sa.Numeric(precision=8, scale=2), nullable=True),
        sa.Column("duration_seconds", sa.Integer(), nullable=True),
        sa.Column("distance_meters", sa.Numeric(precision=10, scale=2), nullable=True),
        sa.ForeignKeyConstraint(["workout_record_id"], ["workout_records.id"], name="fk_exercise_sets_record"),
        sa.UniqueConstraint("workout_record_id", "set_index", name="uq_exercise_set_record_index"),
    )
    exercises = sa.table(
        "exercises",
        sa.column("canonical_name", sa.String),
        sa.column("display_name_kr", sa.String),
        sa.column("unit_kind", sa.String),
        sa.column("body_part", sa.String),
    )
    op.bulk_insert(exercises, [
        {"canonical_name": "bench_press", "display_name_kr": "\ubca4\uce58\ud504\ub808\uc2a4", "unit_kind": "reps_weight", "body_part": "chest"},
        {"canonical_name": "barbell_row", "display_name_kr": "\ubc14\ubca8 \ub85c\uc6b0", "unit_kind": "reps_weight", "body_part": "back"},
        {"canonical_name": "squat", "display_name_kr": "\uc2a4\ucffc\ud2b8", "unit_kind": "reps_weight", "body_part": "legs"},
        {"canonical_name": "overhead_press", "display_name_kr": "\uc624\ubc84\ud5e4\ub4dc \ud504\ub808\uc2a4", "unit_kind": "reps_weight", "body_part": "shoulders"},
        {"canonical_name": "bicep_curl", "display_name_kr": "\ubc14\uc774\uc149 \uceec", "unit_kind": "reps_weight", "body_part": "arms"},
        {"canonical_name": "plank", "display_name_kr": "\ud50c\ub7ad\ud06c", "unit_kind": "time", "body_part": "core"},
        {"canonical_name": "running", "display_name_kr": "\ub7ec\ub2dd", "unit_kind": "distance", "body_part": "stamina"},
    ])


def downgrade() -> None:
    op.drop_table("exercise_sets")
    op.drop_index("ix_workout_records_user_performed_at", table_name="workout_records")
    op.drop_table("workout_records")
    op.drop_table("exercises")
