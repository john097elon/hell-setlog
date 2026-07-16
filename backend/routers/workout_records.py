"""Structured, immutable workout record API."""

import base64
import json
from datetime import date, datetime, time, timezone
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from sqlalchemy import and_, or_
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from auth import get_current_user
from database import get_db
from growth import BODY_PARTS
from models import Exercise, ExerciseSet, User, Workout, WorkoutRecord, utcnow
from schemas import (
    ExerciseOut,
    WorkoutRecordCalendar,
    WorkoutRecordCalendarDay,
    WorkoutRecordCreate,
    WorkoutRecordOut,
    WorkoutRecordPage,
)

router = APIRouter(tags=["workout-records"])

DEFAULT_EXERCISES = (
    ("bench_press", "벤치프레스", "reps_weight", "chest"),
    ("barbell_row", "바벨 로우", "reps_weight", "back"),
    ("squat", "스쿼트", "reps_weight", "legs"),
    ("overhead_press", "오버헤드 프레스", "reps_weight", "shoulders"),
    ("bicep_curl", "바이셉 컬", "reps_weight", "arms"),
    ("plank", "플랭크", "time", "core"),
    ("running", "러닝", "distance", "stamina"),
)


def _ensure_catalog(db: Session) -> None:
    if db.query(Exercise.id).first() is None:
        db.add_all(
            Exercise(
                canonical_name=canonical_name,
                display_name_kr=display_name_kr,
                unit_kind=unit_kind,
                body_part=body_part,
            )
            for canonical_name, display_name_kr, unit_kind, body_part in DEFAULT_EXERCISES
        )
        db.commit()


def _record_query(db: Session):
    return db.query(WorkoutRecord).options(
        joinedload(WorkoutRecord.exercise), joinedload(WorkoutRecord.sets)
    )


def _to_out(record: WorkoutRecord) -> WorkoutRecordOut:
    return WorkoutRecordOut.model_validate(record)


def _validate_sets(unit_kind: str, sets) -> None:
    if not sets:
        raise HTTPException(status_code=422, detail="at least one set is required")
    indexes = [item.set_index for item in sets]
    if len(indexes) != len(set(indexes)):
        raise HTTPException(status_code=422, detail="set_index must be unique")
    expected = {
        "reps_weight": {"reps", "weight_kg"},
        "time": {"duration_seconds"},
        "distance": {"distance_meters"},
    }[unit_kind]
    fields = {"reps", "weight_kg", "duration_seconds", "distance_meters"}
    for item in sets:
        values = item.model_dump()
        if any(values[field] is not None for field in fields - expected):
            raise HTTPException(status_code=422, detail="set fields do not match exercise unit_kind")
        if any(values[field] is None for field in expected):
            raise HTTPException(status_code=422, detail="set fields do not match exercise unit_kind")


def _same_request(record: WorkoutRecord, body: WorkoutRecordCreate) -> bool:
    if record.workout_id != body.workout_id or record.exercise_id != body.exercise_id:
        return False
    actual = [
        (item.set_index, item.reps, float(item.weight_kg) if item.weight_kg is not None else None,
         item.duration_seconds, float(item.distance_meters) if item.distance_meters is not None else None)
        for item in record.sets
    ]
    requested = [
        (item.set_index, item.reps, item.weight_kg, item.duration_seconds, item.distance_meters)
        for item in sorted(body.sets, key=lambda item: item.set_index)
    ]
    return actual == requested


def _encode_cursor(record: WorkoutRecord) -> str:
    performed_at = record.performed_at
    if performed_at.tzinfo is None:
        performed_at = performed_at.replace(tzinfo=timezone.utc)
    payload = {"performed_at": performed_at.isoformat(), "id": record.id}
    return base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip("=")


def _decode_cursor(cursor: str) -> tuple[datetime, int]:
    try:
        padding = "=" * (-len(cursor) % 4)
        payload = json.loads(base64.urlsafe_b64decode(cursor + padding))
        performed_at = datetime.fromisoformat(payload["performed_at"])
        if performed_at.tzinfo is None or not isinstance(payload["id"], int):
            raise ValueError
        return performed_at, payload["id"]
    except (KeyError, TypeError, ValueError, json.JSONDecodeError):
        raise HTTPException(status_code=400, detail="invalid cursor")


@router.get("/exercises", response_model=list[ExerciseOut])
def list_exercises(
    body_part: str | None = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    del current_user
    if body_part is not None and body_part not in BODY_PARTS:
        raise HTTPException(status_code=422, detail="invalid body_part")
    _ensure_catalog(db)
    query = db.query(Exercise)
    if body_part:
        query = query.filter(Exercise.body_part == body_part)
    return query.order_by(Exercise.id).all()


@router.post("/workout-records", response_model=WorkoutRecordOut, status_code=status.HTTP_201_CREATED)
def create_workout_record(
    body: WorkoutRecordCreate,
    idempotency_key: str | None = Header(None, alias="X-Idempotency-Key", max_length=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _ensure_catalog(db)
    if idempotency_key:
        existing = (
            _record_query(db)
            .filter(
                WorkoutRecord.user_id == current_user.id,
                WorkoutRecord.idempotency_key == idempotency_key,
            )
            .first()
        )
        if existing:
            if not _same_request(existing, body):
                raise HTTPException(
                    status_code=409,
                    detail="idempotency key already used with a different request",
                )
            return _to_out(existing)

    workout = db.query(Workout).filter(Workout.id == body.workout_id).with_for_update().first()
    if not workout or workout.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Workout not found")
    if workout.status != "active":
        raise HTTPException(status_code=409, detail={"message": "진행 중인 운동에만 기록할 수 있습니다"})
    exercise = db.query(Exercise).filter(Exercise.id == body.exercise_id).first()
    if not exercise:
        raise HTTPException(status_code=404, detail="Exercise not found")
    _validate_sets(exercise.unit_kind, body.sets)

    performed_at = body.performed_at or utcnow()
    if performed_at.tzinfo is None:
        performed_at = performed_at.replace(tzinfo=timezone.utc)
    record = WorkoutRecord(
        workout_id=workout.id,
        user_id=current_user.id,
        exercise_id=exercise.id,
        performed_at=performed_at,
        status="submitted",
        idempotency_key=idempotency_key,
    )
    db.add(record)
    try:
        db.flush()
    except IntegrityError:
        db.rollback()
        existing = (
            _record_query(db)
            .filter(
                WorkoutRecord.user_id == current_user.id,
                WorkoutRecord.idempotency_key == idempotency_key,
            )
            .first()
        )
        if not idempotency_key or not existing:
            raise
        if not _same_request(existing, body):
            raise HTTPException(
                status_code=409,
                detail="idempotency key already used with a different request",
            )
        return _to_out(existing)
    for item in body.sets:
        db.add(ExerciseSet(workout_record_id=record.id, **item.model_dump()))
    db.commit()
    record = _record_query(db).filter(WorkoutRecord.id == record.id).one()
    return _to_out(record)


@router.get("/workout-records/calendar", response_model=WorkoutRecordCalendar)
def workout_record_calendar(
    from_date: date = Query(..., alias="from"),
    to_date: date = Query(..., alias="to"),
    tz: str = Query(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if to_date < from_date:
        raise HTTPException(status_code=400, detail="invalid date range")
    try:
        zone = ZoneInfo(tz)
    except ZoneInfoNotFoundError:
        raise HTTPException(status_code=400, detail="invalid tz")
    start = datetime.combine(from_date, time.min, tzinfo=zone).astimezone(timezone.utc)
    end = datetime.combine(to_date, time.max, tzinfo=zone).astimezone(timezone.utc)
    records = (
        _record_query(db)
        .filter(WorkoutRecord.user_id == current_user.id, WorkoutRecord.performed_at >= start, WorkoutRecord.performed_at <= end)
        .order_by(WorkoutRecord.performed_at)
        .all()
    )
    grouped: dict[date, list[WorkoutRecord]] = {}
    for record in records:
        performed_at = record.performed_at
        if performed_at.tzinfo is None:
            performed_at = performed_at.replace(tzinfo=timezone.utc)
        grouped.setdefault(performed_at.astimezone(zone).date(), []).append(record)
    return WorkoutRecordCalendar(days=[
        WorkoutRecordCalendarDay(
            date=day.isoformat(),
            record_count=len(items),
            body_parts=[part for part in BODY_PARTS if any(item.exercise.body_part == part for item in items)],
        )
        for day, items in sorted(grouped.items())
    ])


@router.get("/workout-records/{record_id}", response_model=WorkoutRecordOut)
def get_workout_record(
    record_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    record = _record_query(db).filter(WorkoutRecord.id == record_id).first()
    if not record or record.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Workout record not found")
    return _to_out(record)


@router.get("/workout-records", response_model=WorkoutRecordPage)
def list_workout_records(
    workout_id: int | None = None,
    body_part: str | None = None,
    from_at: datetime | None = Query(None, alias="from"),
    to_at: datetime | None = Query(None, alias="to"),
    cursor: str | None = None,
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if body_part is not None and body_part not in BODY_PARTS:
        raise HTTPException(status_code=422, detail="invalid body_part")
    query = _record_query(db).filter(WorkoutRecord.user_id == current_user.id)
    if workout_id is not None:
        query = query.filter(WorkoutRecord.workout_id == workout_id)
    if body_part is not None:
        query = query.join(WorkoutRecord.exercise).filter(Exercise.body_part == body_part)
    if from_at is not None:
        query = query.filter(WorkoutRecord.performed_at >= from_at)
    if to_at is not None:
        query = query.filter(WorkoutRecord.performed_at <= to_at)
    if cursor is not None:
        cursor_at, cursor_id = _decode_cursor(cursor)
        query = query.filter(
            or_(WorkoutRecord.performed_at < cursor_at, and_(WorkoutRecord.performed_at == cursor_at, WorkoutRecord.id < cursor_id))
        )
    records = query.order_by(WorkoutRecord.performed_at.desc(), WorkoutRecord.id.desc()).limit(limit + 1).all()
    has_more = len(records) > limit
    items = records[:limit]
    return WorkoutRecordPage(
        items=[_to_out(record) for record in items],
        has_more=has_more,
        next_cursor=_encode_cursor(items[-1]) if has_more and items else None,
    )
