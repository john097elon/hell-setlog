"""Router: Workout and Setlog management."""
import random
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from database import get_db
from auth import get_current_user
from models import User, Workout, Setlog, PartyMember, BodyStat, Character
from schemas import (
    WorkoutCreate,
    WorkoutUpdate,
    WorkoutOut,
    SetlogCreate,
    SetlogOut,
    Breakthrough,
    BodyStatSummary,
    WorkoutEndResponse,
)

router = APIRouter(prefix="/workouts", tags=["workouts"])

# The 7 BodyStat parts
BODY_PARTS = ["chest", "back", "legs", "shoulders", "arms", "core", "stamina"]


def _check_party_membership(db: Session, user_id: int, party_id: int) -> bool:
    """Check if user is a member of the party."""
    return (
        db.query(PartyMember)
        .filter(
            PartyMember.party_id == party_id,
            PartyMember.user_id == user_id,
            PartyMember.status == "active",
        )
        .first()
        is not None
    )


# ── Workouts ────────────────────────────────────────────────────────────────

@router.post("/", response_model=WorkoutOut, status_code=status.HTTP_201_CREATED)
def create_workout(
    body: WorkoutCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Start a new workout."""
    if body.party_id and not _check_party_membership(db, current_user.id, body.party_id):
        raise HTTPException(status_code=403, detail="Not a member of this party")

    workout = Workout(
        user_id=current_user.id,
        party_id=body.party_id,
        notes=body.notes,
        status="active",
    )
    db.add(workout)
    db.commit()
    db.refresh(workout)
    return workout


@router.get("/", response_model=list[WorkoutOut])
def list_workouts(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List current user's workouts."""
    return (
        db.query(Workout)
        .filter(Workout.user_id == current_user.id)
        .order_by(Workout.started_at.desc())
        .all()
    )


@router.get("/{workout_id}", response_model=WorkoutOut)
def get_workout(
    workout_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get a single workout with its setlogs."""
    workout = db.query(Workout).filter(Workout.id == workout_id).first()
    if not workout:
        raise HTTPException(status_code=404, detail="Workout not found")
    return workout


@router.patch("/{workout_id}", response_model=WorkoutOut)
def update_workout(
    workout_id: int,
    body: WorkoutUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update workout status, ended_at, or notes."""
    workout = db.query(Workout).filter(Workout.id == workout_id).first()
    if not workout:
        raise HTTPException(status_code=404, detail="Workout not found")
    if workout.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your workout")

    if body.status is not None:
        workout.status = body.status
    if body.ended_at is not None:
        workout.ended_at = body.ended_at
    if body.notes is not None:
        workout.notes = body.notes

    db.commit()
    db.refresh(workout)
    return workout


# ── Workout End + Character Growth ─────────────────────────────────────────

@router.post("/{workout_id}/end")
def end_workout(
    workout_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """End a workout and calculate character growth across all 7 body parts."""
    # 1. Validate workout belongs to user and is active
    workout = db.query(Workout).filter(Workout.id == workout_id).first()
    if not workout:
        raise HTTPException(status_code=404, detail="Workout not found")
    if workout.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your workout")
    if workout.status != "active":
        raise HTTPException(status_code=400, detail="Workout is not active")

    # 2. Set workout as ended (frontend contract)
    now = datetime.now(timezone.utc)
    workout.status = "ended"
    workout.ended_at = now

    # 3. Get user's character
    if not current_user.character_id:
        raise HTTPException(status_code=404, detail="No character found")

    character = db.query(Character).filter(Character.id == current_user.character_id).first()
    if not character:
        raise HTTPException(status_code=404, detail="Character not found")

    # 4. Get all 7 BodyStats for this character
    body_stats = (
        db.query(BodyStat)
        .filter(BodyStat.character_id == character.id)
        .all()
    )
    # Ensure we have all 7 — create any missing ones
    existing_parts = {bs.part for bs in body_stats}
    for part in BODY_PARTS:
        if part not in existing_parts:
            new_stat = BodyStat(
                character_id=character.id,
                part=part,
                level=1,
                potential=0,
            )
            db.add(new_stat)
            body_stats.append(new_stat)

    # 5. Calculate growth for each body part
    breakthroughs: list[Breakthrough] = []
    all_stats: list[BodyStatSummary] = []

    for bs in body_stats:
        gain = random.randint(5, 15)
        bs.potential += gain

        # Level up if potential >= 100
        if bs.potential >= 100:
            old_level = bs.level
            bs.level += 1
            bs.potential -= 100
            breakthroughs.append(Breakthrough(
                part=bs.part,
                old_level=old_level,
                new_level=bs.level,
            ))

        all_stats.append(BodyStatSummary(
            part=bs.part,
            level=bs.level,
            potential=bs.potential,
        ))

    # 6. Auto-generate an "end" setlog summarizing the workout
    setlog_count = (
        db.query(Setlog).filter(Setlog.workout_id == workout_id).count()
    )
    # Build a human-readable part summary based on setlog contents
    part_counts: dict[str, int] = {}
    setlogs = db.query(Setlog).filter(Setlog.workout_id == workout_id).all()
    for s in setlogs:
        if s.type == "mid":
            content_lower = s.content.lower()
            for part in BODY_PARTS:
                # Simple keyword matching
                part_kr = {
                    "chest": "가슴",
                    "back": "등",
                    "legs": "하체",
                    "shoulders": "어깨",
                    "arms": "팔",
                    "core": "코어",
                    "stamina": "유산소",
                }
                if part_kr.get(part, part) in content_lower:
                    part_counts[part] = part_counts.get(part, 0) + 1

    if part_counts:
        summary_parts = [f"{part_kr.get(p, p)} {c}세트" for p, c in part_counts.items()]
        summary = f"{', '.join(summary_parts)} 완료 - 총 {setlog_count}개 세트로그"
    else:
        summary = f"운동 완료 - 총 {setlog_count}개 세트로그"

    end_setlog = Setlog(
        workout_id=workout_id,
        user_id=current_user.id,
        type="end",
        content=summary,
    )
    db.add(end_setlog)

    db.commit()
    db.refresh(workout)

    # Build the simplified workout output
    workout_out = WorkoutOut(
        id=workout.id,
        user_id=workout.user_id,
        party_id=workout.party_id,
        started_at=workout.started_at,
        ended_at=workout.ended_at,
        status=workout.status,
        notes=workout.notes,
    )

    duration_seconds = int((workout.ended_at - workout.started_at).total_seconds()) if workout.ended_at and workout.started_at else None
    return {
        **workout_out.model_dump(),
        "duration_seconds": duration_seconds,
        "setlog_count": setlog_count + 1,
        "breakthroughs": [b.model_dump() for b in breakthroughs],
        "body_stats": [s.model_dump() for s in all_stats],
        # Backward-compatible keys for any existing callers.
        "workout": workout_out.model_dump(),
        "all_stats": [s.model_dump() for s in all_stats],
    }


# ── Setlogs ─────────────────────────────────────────────────────────────────

@router.post("/{workout_id}/setlogs", response_model=SetlogOut, status_code=status.HTTP_201_CREATED)
async def add_setlog(
    workout_id: int,
    body: SetlogCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Add a setlog entry to a workout. Accepts JSON body with type and content."""
    workout = db.query(Workout).filter(Workout.id == workout_id).first()
    if not workout:
        raise HTTPException(status_code=404, detail="Workout not found")
    if workout.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your workout")

    setlog = Setlog(
        workout_id=workout_id,
        user_id=current_user.id,
        type=body.type,
        content=body.content,
        file_path=body.file_path,
    )
    db.add(setlog)
    db.commit()
    db.refresh(setlog)
    return setlog


@router.get("/{workout_id}/setlogs", response_model=list[SetlogOut])
def list_setlogs(
    workout_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get all setlogs for a workout."""
    workout = db.query(Workout).filter(Workout.id == workout_id).first()
    if not workout:
        raise HTTPException(status_code=404, detail="Workout not found")
    return (
        db.query(Setlog)
        .filter(Setlog.workout_id == workout_id)
        .order_by(Setlog.created_at.asc())
        .all()
    )
