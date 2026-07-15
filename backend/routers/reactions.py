"""Router: Reactions (emoji reactions on setlogs and workouts)."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth import get_current_user
from database import get_db
from models import PartyMember, Reaction, Setlog, User, Workout
from schemas import ReactionCreate, ReactionOut

router = APIRouter(prefix="/reactions", tags=["reactions"])


def _require_active_party_member(
    db: Session, user_id: int, party_id: int | None
) -> None:
    if party_id is None:
        return
    membership = (
        db.query(PartyMember)
        .filter(
            PartyMember.party_id == party_id,
            PartyMember.user_id == user_id,
            PartyMember.status == "active",
        )
        .first()
    )
    if not membership:
        raise HTTPException(status_code=403, detail="Active party membership required")


def _check_reaction_permission(
    db: Session, user_id: int, target_type: str, target_id: int
) -> None:
    if target_type == "workout":
        workout = db.query(Workout).filter(Workout.id == target_id).first()
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")
        if workout.party_id is None:
            # Personal workout: only owner can react/modify reactions
            if workout.user_id != user_id:
                raise HTTPException(status_code=403, detail="Active party membership required")
        else:
            # Party workout: only active party members can react/modify reactions
            _require_active_party_member(db, user_id, workout.party_id)
    else: # setlog
        setlog = db.query(Setlog).filter(Setlog.id == target_id).first()
        if not setlog:
            raise HTTPException(status_code=404, detail="Setlog not found")
        workout = db.query(Workout).filter(Workout.id == setlog.workout_id).first()
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")
        if workout.party_id is None:
            # Personal workout: only owner can react/modify reactions
            if workout.user_id != user_id:
                raise HTTPException(status_code=403, detail="Active party membership required")
        else:
            # Party workout: only active party members can react/modify reactions
            _require_active_party_member(db, user_id, workout.party_id)


@router.post("/", response_model=ReactionOut, status_code=status.HTTP_201_CREATED)
def add_reaction(
    body: ReactionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Add a reaction to a setlog or workout."""
    _check_reaction_permission(db, current_user.id, body.target_type, body.target_id)

    # Check for duplicate reaction (same user, target, emoji)
    existing = (
        db.query(Reaction)
        .filter(
            Reaction.user_id == current_user.id,
            Reaction.target_type == body.target_type,
            Reaction.target_id == body.target_id,
            Reaction.emoji == body.emoji,
        )
        .first()
    )
    if existing:
        raise HTTPException(status_code=409, detail="Already reacted with this emoji")

    reaction = Reaction(
        user_id=current_user.id,
        target_type=body.target_type,
        target_id=body.target_id,
        emoji=body.emoji,
    )
    db.add(reaction)
    db.commit()
    db.refresh(reaction)
    return reaction


@router.delete("/{reaction_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_reaction(
    reaction_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Remove your own reaction."""
    reaction = db.query(Reaction).filter(Reaction.id == reaction_id).first()
    if not reaction:
        raise HTTPException(status_code=404, detail="Reaction not found")
    if reaction.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your reaction")

    _check_reaction_permission(db, current_user.id, reaction.target_type, reaction.target_id)

    db.delete(reaction)
    db.commit()
