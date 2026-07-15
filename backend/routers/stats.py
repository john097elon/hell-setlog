"""Router: BodyStat management."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from auth import get_current_user
from database import get_db
from models import BodyStat, User
from schemas import BodyStatOut

router = APIRouter(prefix="/stats", tags=["stats"])


@router.get("/", response_model=list[BodyStatOut])
def get_my_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get all body stats for the current user's character."""
    if not current_user.character_id:
        raise HTTPException(status_code=404, detail="No character found")

    return (
        db.query(BodyStat)
        .filter(BodyStat.character_id == current_user.character_id)
        .all()
    )
# PATCH /stats/{part} removed — growth is written exclusively by the server's
# workout-end engine. Client writes to this endpoint were a P0 growth fraud vector.
