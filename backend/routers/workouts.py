"""Router: Workout and Setlog management."""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth import get_current_user
from database import get_db
from growth import _PART_KW_KR as PART_KEYWORDS
from growth import BODY_PARTS, FORMULA_VERSION, compute_growth, today_utc_start
from models import (
    BodyStat,
    Character,
    GrowthEvent,
    PartyMember,
    Setlog,
    User,
    Workout,
    WorkoutRecord,
)
from schemas import (
    BodyStatSummary,
    Breakthrough,
    CharacterOut,
    SetlogCreate,
    SetlogOut,
    WorkoutCreate,
    WorkoutEndResponse,
    WorkoutOut,
    WorkoutUpdate,
)
from storage import ObjectNotFound, ObjectStorage, get_storage

router = APIRouter(prefix="/workouts", tags=["workouts"])


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
    """Start a new workout. A user may have at most one active workout."""
    if body.party_id and not _check_party_membership(
        db, current_user.id, body.party_id
    ):
        raise HTTPException(status_code=403, detail="Not a member of this party")

    active = (
        db.query(Workout)
        .filter(Workout.user_id == current_user.id, Workout.status == "active")
        .first()
    )
    if active:
        raise HTTPException(
            status_code=409,
            detail={
                "message": "이미 진행 중인 운동이 있습니다",
                "active_workout_id": active.id,
            },
        )

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
    """Get a single workout. Only the owner may read full workout details."""
    workout = db.query(Workout).filter(Workout.id == workout_id).first()
    # Return 404 whether not found or unauthorized (prevents ID enumeration)
    if not workout or workout.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Workout not found")
    return workout


@router.patch("/{workout_id}", response_model=WorkoutOut)
def update_workout(
    workout_id: int,
    body: WorkoutUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update workout notes. Status transitions are managed by the server via /end."""
    workout = db.query(Workout).filter(Workout.id == workout_id).first()
    if not workout or workout.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Workout not found")

    # Only notes may be updated via PATCH; status/ended_at are server-managed
    if body.notes is not None:
        workout.notes = body.notes

    db.commit()
    db.refresh(workout)
    return workout


@router.post("/{workout_id}/cancel", response_model=WorkoutOut)
def cancel_workout(
    workout_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Cancel an active workout without awarding character growth."""
    workout = db.query(Workout).filter(Workout.id == workout_id).first()
    if not workout or workout.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Workout not found")
    if workout.status == "cancelled":
        return workout
    if workout.status != "active":
        raise HTTPException(status_code=409, detail="Only an active workout can be cancelled")

    workout.status = "cancelled"
    workout.ended_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(workout)
    return workout


# Workout End + GrowthEvent Engine

def _growth_response(workout, growth_events: list, db: Session) -> dict:
    """Build end-workout response from persisted GrowthEvents."""
    db.refresh(workout)
    setlog_count = db.query(Setlog).filter(Setlog.workout_id == workout.id).count()
    duration_seconds = (
        int((workout.ended_at - workout.started_at).total_seconds())
        if workout.ended_at and workout.started_at
        else None
    )
    workout_out = WorkoutOut(
        id=workout.id,
        user_id=workout.user_id,
        party_id=workout.party_id,
        started_at=workout.started_at,
        ended_at=workout.ended_at,
        status=workout.status,
        notes=workout.notes,
    )
    breakthroughs = [
        Breakthrough(
            part=ge.body_part, old_level=ge.level_before, new_level=ge.level_after
        )
        for ge in growth_events
        if ge.level_after > ge.level_before
    ]
    all_stats = [
        BodyStatSummary(
            part=ge.body_part, level=ge.level_after, potential=ge.potential_after
        )
        for ge in growth_events
    ]
    character = None
    if workout.user and workout.user.character_id:
        character_obj = db.query(Character).filter(Character.id == workout.user.character_id).first()
        if character_obj:
            character = CharacterOut.model_validate(character_obj)

    return {
        "workout": workout_out.model_dump(),
        "breakthroughs": [b.model_dump() for b in breakthroughs],
        "all_stats": [s.model_dump() for s in all_stats],
        "body_stats": [s.model_dump() for s in all_stats],
        "duration_seconds": duration_seconds,
        "setlog_count": setlog_count,
        "character": character.model_dump() if character else None,
        **workout_out.model_dump(),
    }


@router.post("/{workout_id}/end", response_model=WorkoutEndResponse)
def end_workout(
    workout_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """End a workout; compute and persist GrowthEvents for all 7 body parts.

    Idempotent: already-ended workouts return the original GrowthEvent results.
    """
    workout = db.query(Workout).filter(Workout.id == workout_id).first()
    if not workout or workout.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Workout not found")

    # Claim the active-to-ended transition in this transaction. The conditional
    # update prevents concurrent requests from awarding growth twice.
    now = datetime.now(timezone.utc)
    won = (
        db.query(Workout)
        .filter(Workout.id == workout_id, Workout.status == "active")
        .update(
            {Workout.status: "ended", Workout.ended_at: now},
            synchronize_session=False,
        )
    )
    if not won:
        db.rollback()
        fresh = db.query(Workout).filter(Workout.id == workout_id).first()
        events = (
            db.query(GrowthEvent)
            .filter(GrowthEvent.workout_id == workout_id)
            .order_by(GrowthEvent.id)
            .all()
        )
        return _growth_response(fresh, events, db)
    db.refresh(workout)

    if not current_user.character_id:
        raise HTTPException(status_code=404, detail="No character found")
    character = (
        db.query(Character).filter(Character.id == current_user.character_id).first()
    )
    if not character:
        raise HTTPException(status_code=404, detail="Character not found")

    # Ensure all 7 BodyStats exist
    body_stats_map: dict[str, BodyStat] = {
        bs.part: bs
        for bs in db.query(BodyStat).filter(BodyStat.character_id == character.id).all()
    }
    for part in BODY_PARTS:
        if part not in body_stats_map:
            new_stat = BodyStat(
                character_id=character.id, part=part, level=1, potential=0
            )
            db.add(new_stat)
            db.flush()
            body_stats_map[part] = new_stat

    # Compute duration
    started_at = workout.started_at
    if started_at and started_at.tzinfo is None:
        started_at = started_at.replace(tzinfo=timezone.utc)
    duration_seconds = int((now - started_at).total_seconds()) if started_at else 0

    # Collect setlog text for part detection
    setlogs = db.query(Setlog).filter(Setlog.workout_id == workout_id).all()
    contents = [s.content for s in setlogs]
    # Structured records use the established keyword input adapter. GrowthEvent
    # creation stays exclusively in this endpoint and retains its DB idempotency.
    structured_records = (
        db.query(WorkoutRecord)
        .filter(WorkoutRecord.workout_id == workout_id)
        .all()
    )
    contents.extend(PART_KEYWORDS[record.exercise.body_part] for record in structured_records)

    # Daily cap: sum deltas already granted today per part
    daily_used: dict[str, int] = {}
    for ge in (
        db.query(GrowthEvent)
        .filter(
            GrowthEvent.user_id == current_user.id,
            GrowthEvent.created_at >= today_utc_start(),
        )
        .all()
    ):
        daily_used[ge.body_part] = daily_used.get(ge.body_part, 0) + ge.delta

    current_stats = {p: (bs.level, bs.potential) for p, bs in body_stats_map.items()}
    growths = compute_growth(duration_seconds, contents, current_stats, daily_used)

    # Persist GrowthEvents and update BodyStats
    growth_events: list[GrowthEvent] = []
    for g in growths:
        ge = GrowthEvent(
            user_id=current_user.id,
            workout_id=workout_id,
            body_part=g.body_part,
            delta=g.delta,
            reason=g.reason,
            formula_version=FORMULA_VERSION,
            level_before=g.level_before,
            potential_before=g.potential_before,
            level_after=g.level_after,
            potential_after=g.potential_after,
        )
        db.add(ge)
        bs = body_stats_map[g.body_part]
        bs.level = g.level_after
        bs.potential = g.potential_after
        growth_events.append(ge)

    # Auto-generate end setlog summary
    part_counts: dict[str, int] = {}
    for s in setlogs:
        if s.type == "mid":
            cl = s.content.lower()
            for ge in growth_events:
                from growth import _PART_KW_KR

                kw = _PART_KW_KR.get(ge.body_part, ge.body_part)
                if kw in cl:
                    part_counts[ge.body_part] = part_counts.get(ge.body_part, 0) + 1
    from growth import _PART_KW_KR as _KW

    if part_counts:
        summary = ", ".join(f"{_KW.get(p, p)} {c}세트" for p, c in part_counts.items())
        summary += f" 완료 - 총 {len(setlogs)}개 세트로그"
    else:
        summary = f"운동 완료 - 총 {len(setlogs)}개 세트로그"
    db.add(
        Setlog(
            workout_id=workout_id, user_id=current_user.id, type="end", content=summary
        )
    )

    db.commit()
    db.refresh(workout)

    return _growth_response(workout, growth_events, db)


# ── Setlogs ─────────────────────────────────────────────────────────────────


@router.post(
    "/{workout_id}/setlogs",
    response_model=SetlogOut,
    status_code=status.HTTP_201_CREATED,
)
async def add_setlog(
    workout_id: int,
    body: SetlogCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    storage: ObjectStorage = Depends(get_storage),
):
    """Add a setlog entry. Requires text content or an owned media reference."""
    workout = db.query(Workout).filter(Workout.id == workout_id).first()
    if not workout or workout.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Workout not found")

    if workout.status != "active":
        raise HTTPException(status_code=409, detail="진행 중인 운동에만 기록할 수 있습니다")

    if not body.content.strip() and not body.file_path:
        raise HTTPException(status_code=422, detail="내용 또는 사진 중 하나는 필요합니다")

    if body.file_path:
        # The uploaded object key must belong to this user and actually exist.
        if not body.file_path.startswith(f"users/{current_user.id}/"):
            raise HTTPException(status_code=403, detail="본인이 업로드한 미디어만 첨부할 수 있습니다")
        try:
            storage.head(body.file_path)
        except ObjectNotFound:
            raise HTTPException(status_code=422, detail="첨부하려는 미디어를 찾을 수 없습니다")

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
    """Get all setlogs for a workout. Only the owner may read setlogs."""
    workout = db.query(Workout).filter(Workout.id == workout_id).first()
    # 404 for both not-found and unauthorized to prevent ID enumeration
    if not workout or workout.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Workout not found")
    return (
        db.query(Setlog)
        .filter(Setlog.workout_id == workout_id)
        .order_by(Setlog.created_at.asc())
        .all()
    )
