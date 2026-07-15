"""Router: Party management (create, join, list, details, feed)."""

from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session, joinedload

from auth import get_current_user
from database import get_db
from models import GrowthEvent, Party, PartyMember, Reaction, Setlog, User, Workout
from schemas import (
    FeedEvent,
    FeedEventData,
    PartyCreate,
    PartyJoin,
    PartyOut,
)

router = APIRouter(prefix="/parties", tags=["parties"])

RANDOM_MAX_MEMBERS = 4

RANDOM_PARTY_NAMES = [
    "불타는 헬창단",
    "지옥의 스쿼터",
    "덤벨 전사들",
    "근육의 제왕",
    "땀방울 전사단",
    "철권 엘리트",
    "바벨 브라더스",
    "아이언 피트니스",
    "맷돌 핏단",
    "헬스 오브 레전드",
    "무쇠팟",
    "핏불 크루",
    "인크레더블 벌크",
    "스트롱홀드",
    "파워리프터 길드",
    "근성 헬스단",
    "불굴의 피트니스",
    "절대 근육단",
    "아이언 클랜",
    "핏 파이터즈",
    "근육 하나캡",
    "철인 전사단",
    "역도 천재들",
    "스쿼트 킹덤",
    "벤치프레스 마스터즈",
    "데드리프트 레전드",
    "하드코어 헬스",
    "맨몸 정복자",
    "쉐이프 업 크루",
    "근육 제너레이션",
]


def _random_party_name() -> str:
    import random

    return random.choice(RANDOM_PARTY_NAMES)


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _generate_invite_code(db: Session) -> str:
    """Generate a random 6-character uppercase alphanumeric invite code."""
    import random
    import string

    while True:
        code = "".join(random.choices(string.ascii_uppercase + string.digits, k=6))
        if not db.query(Party).filter(Party.invite_code == code).first():
            return code


def _active_membership(db: Session, party_id: int, user_id: int) -> PartyMember | None:
    return (
        db.query(PartyMember)
        .filter(
            PartyMember.party_id == party_id,
            PartyMember.user_id == user_id,
            PartyMember.status == "active",
        )
        .first()
    )


def _require_active_member(db: Session, party_id: int, user_id: int) -> PartyMember:
    membership = _active_membership(db, party_id, user_id)
    if not membership:
        raise HTTPException(status_code=403, detail="Active party membership required")
    return membership


def _active_member_count(db: Session, party_id: int) -> int:
    return (
        db.query(PartyMember)
        .filter(PartyMember.party_id == party_id, PartyMember.status == "active")
        .count()
    )


def _sync_party_open_state(db: Session, party: Party) -> None:
    if party.match_type == "random":
        active_count = _active_member_count(db, party.id)
        party.is_open = 0 < active_count < party.max_members


def _activate_membership(member: PartyMember, role: str = "member") -> PartyMember:
    member.role = role
    member.status = "active"
    member.left_at = None
    member.joined_at = _now()
    return member


@router.get("/random-browse", response_model=list[PartyOut])
def browse_random_parties(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List all open random parties that have space and exclude kicked parties."""
    blocked_party_ids = select(PartyMember.party_id).filter(
        PartyMember.user_id == current_user.id,
        PartyMember.status == "kicked",
    )
    counts = (
        db.query(PartyMember.party_id, func.count(PartyMember.id).label("active_count"))
        .filter(PartyMember.status == "active")
        .group_by(PartyMember.party_id)
        .subquery()
    )
    parties = (
        db.query(Party)
        .outerjoin(counts, counts.c.party_id == Party.id)
        .filter(
            Party.match_type == "random",
            Party.is_open == True,  # noqa: E712
            func.coalesce(counts.c.active_count, 0) < Party.max_members,
            Party.id.not_in(blocked_party_ids),
        )
        .order_by(Party.created_at.desc())
        .all()
    )
    return parties


@router.post("/", response_model=PartyOut, status_code=status.HTTP_201_CREATED)
def create_party(
    body: PartyCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new manual party. Creator becomes owner and first member."""
    party = Party(
        name=body.name,
        invite_code=_generate_invite_code(db),
        owner_id=current_user.id,
        match_type="manual",
        max_members=RANDOM_MAX_MEMBERS,
        is_open=True,
    )
    db.add(party)
    db.flush()

    db.add(
        PartyMember(
            party_id=party.id, user_id=current_user.id, role="owner", status="active"
        )
    )
    db.commit()
    db.refresh(party)
    return party


@router.post(
    "/random-match", response_model=PartyOut, status_code=status.HTTP_201_CREATED
)
def random_match_party(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Join an existing open online random party or create a persistent one."""
    existing_active = (
        db.query(Party)
        .join(PartyMember, PartyMember.party_id == Party.id)
        .filter(
            Party.match_type == "random",
            PartyMember.user_id == current_user.id,
            PartyMember.status == "active",
        )
        .first()
    )
    if existing_active:
        return existing_active

    counts = (
        db.query(PartyMember.party_id, func.count(PartyMember.id).label("active_count"))
        .filter(PartyMember.status == "active")
        .group_by(PartyMember.party_id)
        .subquery()
    )
    blocked_party_ids = select(PartyMember.party_id).filter(
        PartyMember.user_id == current_user.id,
        PartyMember.status == "kicked",
    )

    excluded_party_ids = set()
    party = None

    while True:
        q = (
            db.query(Party)
            .outerjoin(counts, counts.c.party_id == Party.id)
            .filter(
                Party.match_type == "random",
                Party.is_open == True,  # noqa: E712
                func.coalesce(counts.c.active_count, 0) < Party.max_members,
                Party.id.not_in(blocked_party_ids),
            )
        )
        if excluded_party_ids:
            q = q.filter(Party.id.not_in(excluded_party_ids))

        candidate = (
            q.order_by(
                Party.last_matched_at.is_(None).desc(),
                Party.last_matched_at.asc(),
                Party.created_at.asc(),
            )
            .first()
        )

        if not candidate:
            break

        # Lock the candidate party row
        locked_party = db.query(Party).filter(Party.id == candidate.id).with_for_update().first()
        if locked_party:
            # Recheck capacity under lock
            if _active_member_count(db, locked_party.id) < locked_party.max_members:
                party = locked_party
                break
            else:
                excluded_party_ids.add(locked_party.id)

    now = _now()
    if party is None:
        party = Party(
            name=_random_party_name(),
            invite_code=_generate_invite_code(db),
            owner_id=current_user.id,
            match_type="random",
            max_members=RANDOM_MAX_MEMBERS,
            is_open=True,
            last_matched_at=now,
        )
        db.add(party)
        db.flush()
        db.add(
            PartyMember(
                party_id=party.id,
                user_id=current_user.id,
                role="owner",
                status="active",
            )
        )
    else:
        membership = (
            db.query(PartyMember)
            .filter(
                PartyMember.party_id == party.id, PartyMember.user_id == current_user.id
            )
            .first()
        )
        if membership:
            _activate_membership(membership)
        else:
            db.add(
                PartyMember(
                    party_id=party.id,
                    user_id=current_user.id,
                    role="member",
                    status="active",
                )
            )
        party.last_matched_at = now

    db.flush()
    _sync_party_open_state(db, party)
    db.commit()
    db.refresh(party)
    return party


@router.post("/join", response_model=PartyOut)
def join_party(
    body: PartyJoin,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Join a party by invite code. Soft-left manual members can rejoin."""
    party = db.query(Party).filter(Party.invite_code == body.invite_code).with_for_update().first()
    if not party:
        raise HTTPException(status_code=404, detail="Party not found")

    existing = (
        db.query(PartyMember)
        .filter(
            PartyMember.party_id == party.id, PartyMember.user_id == current_user.id
        )
        .first()
    )
    if existing:
        if existing.status == "active":
            raise HTTPException(
                status_code=409, detail="Already a member of this party"
            )
        if existing.status == "kicked":
            raise HTTPException(
                status_code=403, detail="You were kicked from this party"
            )
        # Check capacity before allowing rejoin
        active_count = _active_member_count(db, party.id)
        if active_count >= party.max_members:
            raise HTTPException(status_code=400, detail="Party is full")
        _activate_membership(existing, role="member")
    else:
        # Check capacity before allowing join
        active_count = _active_member_count(db, party.id)
        if active_count >= party.max_members:
            raise HTTPException(status_code=400, detail="Party is full")
        member = PartyMember(
            party_id=party.id, user_id=current_user.id, role="member", status="active"
        )
        db.add(member)

    db.flush()
    _sync_party_open_state(db, party)
    db.commit()
    db.refresh(party)
    return party


@router.get("/", response_model=list[PartyOut])
def list_parties(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List all parties the current user is an active member of."""
    party_ids = (
        db.query(PartyMember.party_id)
        .filter(PartyMember.user_id == current_user.id, PartyMember.status == "active")
        .subquery()
    )
    return db.query(Party).filter(Party.id.in_(party_ids)).all()


@router.get("/{party_id}", response_model=PartyOut)
def get_party(
    party_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get party details for active members only."""
    party = db.query(Party).filter(Party.id == party_id).first()
    if not party:
        raise HTTPException(status_code=404, detail="Party not found")
    _require_active_member(db, party_id, current_user.id)
    return party


@router.delete("/{party_id}/leave", status_code=status.HTTP_204_NO_CONTENT)
def leave_party(
    party_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Soft leave a party; membership history persists."""
    party = db.query(Party).filter(Party.id == party_id).first()
    if not party:
        raise HTTPException(status_code=404, detail="Party not found")
    membership = _require_active_member(db, party_id, current_user.id)

    membership.status = "left"
    membership.left_at = _now()

    if membership.role == "owner":
        replacement = (
            db.query(PartyMember)
            .filter(
                PartyMember.party_id == party_id,
                PartyMember.status == "active",
                PartyMember.user_id != current_user.id,
            )
            .order_by(PartyMember.joined_at.asc())
            .first()
        )
        if replacement:
            replacement.role = "owner"
            party.owner_id = replacement.user_id
        else:
            party.is_open = False
    db.flush()
    _sync_party_open_state(db, party)
    db.commit()


@router.delete("/{party_id}/members/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def kick_party_member(
    party_id: int,
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Owner-only soft kick endpoint."""
    party = db.query(Party).filter(Party.id == party_id).first()
    if not party:
        raise HTTPException(status_code=404, detail="Party not found")
    owner_membership = _require_active_member(db, party_id, current_user.id)
    if party.owner_id != current_user.id or owner_membership.role != "owner":
        raise HTTPException(
            status_code=403, detail="Only the party owner can kick members"
        )
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Owner cannot kick themselves")

    membership = _active_membership(db, party_id, user_id)
    if not membership:
        raise HTTPException(status_code=404, detail="Active member not found")
    membership.status = "kicked"
    membership.left_at = _now()
    db.flush()
    _sync_party_open_state(db, party)
    db.commit()


# ── Party Feed ──────────────────────────────────────────────────────────────


@router.get("/{party_id}/feed", response_model=list[FeedEvent])
def get_party_feed(
    party_id: int,
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    since: Optional[datetime] = Query(default=None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Return a unified timeline of party activity as flat events for active members."""
    party = db.query(Party).filter(Party.id == party_id).first()
    if not party:
        raise HTTPException(status_code=404, detail="Party not found")
    _require_active_member(db, party_id, current_user.id)

    events: list[dict] = []
    max_candidates = offset + limit

    # 1. Members
    members_q = (
        db.query(PartyMember)
        .options(joinedload(PartyMember.user))
        .filter(PartyMember.party_id == party_id)
    )
    if since:
        members_q = members_q.filter(
            func.coalesce(PartyMember.left_at, PartyMember.joined_at) > since
        )
    members = (
        members_q.order_by(func.coalesce(PartyMember.left_at, PartyMember.joined_at).desc())
        .limit(max_candidates)
        .all()
    )

    for pm in members:
        event_type = "member_joined" if pm.status == "active" else f"member_{pm.status}"
        events.append(
            {
                "id": f"{event_type}:{pm.id}",
                "event_type": event_type,
                "created_at": pm.joined_at
                if pm.status == "active"
                else (pm.left_at or pm.joined_at),
                "user": pm.user,
                "username": pm.user.username if pm.user else "Unknown",
                "data": FeedEventData(
                    user_id=pm.user_id, username=pm.user.username if pm.user else None
                ),
            }
        )

    # 2. Workout start
    workouts_start_q = (
        db.query(Workout)
        .options(joinedload(Workout.user))
        .filter(Workout.party_id == party_id)
    )
    if since:
        workouts_start_q = workouts_start_q.filter(Workout.started_at > since)
    workouts_start = (
        workouts_start_q.order_by(Workout.started_at.desc())
        .limit(max_candidates)
        .all()
    )

    for w in workouts_start:
        events.append(
            {
                "id": f"workout_start:{w.id}",
                "event_type": "workout_start",
                "created_at": w.started_at,
                "user": w.user,
                "username": w.user.username if w.user else "Unknown",
                "workout_id": w.id,
                "content": w.notes,
                "data": FeedEventData(workout_id=w.id, notes=w.notes),
            }
        )

    # 3. Workout end
    workouts_end_q = (
        db.query(Workout)
        .options(joinedload(Workout.user))
        .filter(Workout.party_id == party_id, Workout.ended_at.isnot(None))
    )
    if since:
        workouts_end_q = workouts_end_q.filter(Workout.ended_at > since)
    workouts_end = (
        workouts_end_q.order_by(Workout.ended_at.desc())
        .limit(max_candidates)
        .all()
    )

    # Pre-fetch growth events and setlog counts for ended workouts to avoid N+1 queries
    workout_ids = [w.id for w in workouts_end]
    growth_events_by_workout = {}
    setlog_counts_by_workout = {}
    if workout_ids:
        ge_list = (
            db.query(GrowthEvent)
            .filter(GrowthEvent.workout_id.in_(workout_ids))
            .order_by(GrowthEvent.id)
            .all()
        )
        for ge in ge_list:
            growth_events_by_workout.setdefault(ge.workout_id, []).append(ge)

        counts_q = (
            db.query(Setlog.workout_id, func.count(Setlog.id))
            .filter(Setlog.workout_id.in_(workout_ids))
            .group_by(Setlog.workout_id)
            .all()
        )
        setlog_counts_by_workout = dict(counts_q)

    for w in workouts_end:
        setlog_count = setlog_counts_by_workout.get(w.id, 0)
        duration = (
            int((w.ended_at - w.started_at).total_seconds())
            if w.started_at
            else None
        )
        growth_events = growth_events_by_workout.get(w.id, [])
        breakthroughs = [
            {
                "part": ge.body_part,
                "old_level": ge.level_before,
                "new_level": ge.level_after,
            }
            for ge in growth_events
            if ge.level_after > ge.level_before
        ]
        body_stats = [
            {
                "part": ge.body_part,
                "level": ge.level_after,
                "potential": ge.potential_after,
            }
            for ge in growth_events
        ]
        events.append(
            {
                "id": f"workout_end:{w.id}",
                "event_type": "workout_end",
                "created_at": w.ended_at,
                "user": w.user,
                "username": w.user.username if w.user else "Unknown",
                "workout_id": w.id,
                "target_type": "workout",
                "target_id": w.id,
                "workout_stats": {
                    "duration_seconds": duration,
                    "setlog_count": setlog_count,
                },
                "breakthroughs": breakthroughs,
                "body_stats": body_stats,
                "data": FeedEventData(
                    workout_id=w.id,
                    notes=w.notes,
                    duration_seconds=duration,
                    setlog_count=setlog_count,
                ),
            }
        )

    # 4. Setlogs
    setlogs_q = (
        db.query(Setlog)
        .options(joinedload(Setlog.user))
        .join(Workout, Setlog.workout_id == Workout.id)
        .filter(Workout.party_id == party_id)
    )
    if since:
        setlogs_q = setlogs_q.filter(Setlog.created_at > since)
    setlogs = (
        setlogs_q.order_by(Setlog.created_at.desc())
        .limit(max_candidates)
        .all()
    )

    for s in setlogs:
        events.append(
            {
                "id": f"setlog:{s.id}",
                "event_type": "setlog",
                "created_at": s.created_at,
                "user": s.user,
                "username": s.user.username if s.user else "Unknown",
                "setlog_id": s.id,
                "setlog_type": s.type,
                "content": s.content,
                "file_path": s.file_path,
                "workout_id": s.workout_id,
                "target_type": "setlog",
                "target_id": s.id,
                "data": FeedEventData(
                    setlog_id=s.id,
                    type=s.type,
                    content=s.content,
                    file_path=s.file_path,
                    workout_id=s.workout_id,
                ),
            }
        )

    # 5. Setlog reactions
    setlog_reactions_q = (
        db.query(Reaction)
        .options(joinedload(Reaction.user))
        .join(Setlog, Reaction.target_id == Setlog.id)
        .join(Workout, Setlog.workout_id == Workout.id)
        .filter(Reaction.target_type == "setlog", Workout.party_id == party_id)
    )
    if since:
        setlog_reactions_q = setlog_reactions_q.filter(Reaction.created_at > since)
    setlog_reactions = (
        setlog_reactions_q.order_by(Reaction.created_at.desc())
        .limit(max_candidates)
        .all()
    )

    # 6. Workout reactions
    workout_reactions_q = (
        db.query(Reaction)
        .options(joinedload(Reaction.user))
        .join(Workout, Reaction.target_id == Workout.id)
        .filter(Reaction.target_type == "workout", Workout.party_id == party_id)
    )
    if since:
        workout_reactions_q = workout_reactions_q.filter(Reaction.created_at > since)
    workout_reactions = (
        workout_reactions_q.order_by(Reaction.created_at.desc())
        .limit(max_candidates)
        .all()
    )

    for r in [*setlog_reactions, *workout_reactions]:
        events.append(
            {
                "id": f"reaction:{r.id}",
                "event_type": "reaction",
                "created_at": r.created_at,
                "user": r.user,
                "username": r.user.username if r.user else "Unknown",
                "target_type": r.target_type,
                "target_id": r.target_id,
                "reaction_type": r.emoji,
                "data": FeedEventData(
                    reaction_id=r.id,
                    target_type=r.target_type,
                    target_id=r.target_id,
                    emoji=r.emoji,
                ),
            }
        )

    events.sort(key=lambda e: e["created_at"], reverse=True)
    return events[offset : offset + limit]
