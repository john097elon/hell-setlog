"""Router: BodyStat management."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from database import get_db
from auth import get_current_user
from models import User, BodyStat
from schemas import BodyStatOut, BodyStatUpdate

router = APIRouter(prefix="/stats", tags=["stats"])

VALID_PARTS = {"chest", "back", "legs", "shoulders", "arms", "core", "stamina"}


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


@router.patch("/{part}", response_model=BodyStatOut)
def update_stat(
    part: str,
    body: BodyStatUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a specific body stat for the current user."""
    if part not in VALID_PARTS:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid part '{part}'. Must be one of: {', '.join(sorted(VALID_PARTS))}",
        )

    if not current_user.character_id:
        raise HTTPException(status_code=404, detail="No character found")

    stat = (
        db.query(BodyStat)
        .filter(
            BodyStat.character_id == current_user.character_id,
            BodyStat.part == part,
        )
        .first()
    )
    if not stat:
        raise HTTPException(status_code=404, detail=f"BodyStat '{part}' not found")

    if body.level is not None:
        stat.level = body.level
    if body.potential is not None:
        stat.potential = body.potential

    db.commit()
    db.refresh(stat)
    return stat
