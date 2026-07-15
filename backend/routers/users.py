"""Router: User profile management (tags, etc.)."""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from auth import get_current_user
from database import get_db
from models import User
from schemas import WorkoutTagsUpdate

router = APIRouter(prefix="/users", tags=["users"])


@router.patch("/me/tags")
def update_my_tags(
    body: WorkoutTagsUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update the current user's workout tags."""
    current_user.workout_tags = body.workout_tags
    db.commit()
    return {"workout_tags": current_user.workout_tags}
