"""Router: Workout streak (current streak, longest streak)."""
import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from auth import get_current_user
from models import User, Workout
from streak import compute_streak

router = APIRouter(prefix="/me", tags=["streak"])


@router.get("/streak")
def get_streak(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get current and longest workout streak for the authenticated user.

    A date counts if the user has at least one ended/done workout on that day.
    """
    # Query allended workouts for this user, extract dates
    workouts = (
        db.query(Workout)
        .filter(
            Workout.user_id == current_user.id,
            Workout.status.in_(["ended", "done"]),
        )
        .all()
    )

    workout_dates = [
        w.started_at.date()
        for w in workouts
        if w.started_at is not None
    ]

    return compute_streak(workout_dates)
