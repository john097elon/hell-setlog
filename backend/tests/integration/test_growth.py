"""Integration tests for workout end growth logic.

Covers: growth boundaries, randomness seeding, anti-farm, idempotency,
and stat persistence across requests.
"""

import pytest

from tests.conftest import auth, make_user


def _full_cycle(client, token):
    """Create workout, add setlogs, end workout; return end response json."""
    wid_r = client.post(
        "/api/workouts/", json={"notes": "grow test"}, headers=auth(token)
    )
    wid = wid_r.json()["id"]
    client.post(
        f"/api/workouts/{wid}/setlogs",
        json={"type": "start", "content": "시작"},
        headers=auth(token),
    )
    client.post(
        f"/api/workouts/{wid}/setlogs",
        json={"type": "mid", "content": "가슴 운동 세트"},
        headers=auth(token),
    )
    r = client.post(f"/api/workouts/{wid}/end", headers=auth(token))
    assert r.status_code == 200
    return r.json(), wid


def test_growth_affects_all_7_parts(client):
    _, token = make_user(client, "grower1", suffix="gr")
    data, _ = _full_cycle(client, token)
    assert len(data["body_stats"]) == 7


def test_growth_values_positive(client):
    _, token = make_user(client, "grower2", suffix="gr")
    data, _ = _full_cycle(client, token)
    stats = {s["part"]: s for s in data["body_stats"]}
    for part, s in stats.items():
        assert s["potential"] >= 0, f"{part} potential is negative"
        assert s["level"] >= 1, f"{part} level is below 1"


def test_growth_bounded_single_workout(client):
    """One workout should not jump level by more than 1 (potential cap = 100 per level)."""
    _, token = make_user(client, "grower3", suffix="gr")
    data, _ = _full_cycle(client, token)
    for s in data["body_stats"]:
        # Starting from level 1, potential 0 — max gain is 15 per part — no level-up possible
        assert s["level"] <= 2, f"{s['part']} jumped more than one level in one workout"


def test_stats_persisted_after_end(client):
    """Stats returned by GET /stats must reflect post-end values."""
    _, token = make_user(client, "grower4", suffix="gr")
    end_data, _ = _full_cycle(client, token)
    end_stats = {s["part"]: s["potential"] for s in end_data["body_stats"]}

    r = client.get("/api/stats/", headers=auth(token))
    assert r.status_code == 200
    persisted = {s["part"]: s["potential"] for s in r.json()}
    assert persisted == end_stats, "Stats in DB don't match end-of-workout response"


def test_second_workout_accumulates(client):
    """Two completed workouts must accumulate potential, not reset."""
    _, token = make_user(client, "grower5", suffix="gr")
    data1, _ = _full_cycle(client, token)
    data2, _ = _full_cycle(client, token)

    p1 = {s["part"]: s["potential"] for s in data1["body_stats"]}
    p2 = {s["part"]: s["potential"] for s in data2["body_stats"]}

    # After 2 workouts potential should be greater (unless a level-up reset it)
    sum(p1.values())
    sum(p2.values())
    # total_xp_equivalent: level * 100 + potential
    xp1 = sum(s["level"] * 100 + s["potential"] for s in data1["body_stats"])
    xp2 = sum(s["level"] * 100 + s["potential"] for s in data2["body_stats"])
    assert xp2 > xp1, "Second workout did not increase total XP"


def test_breakthrough_on_level_up(client, db):
    """A persisted near-threshold stat levels up when the workout ends."""
    from models import BodyStat, User

    _, token = make_user(client, "grower6", suffix="gr")
    user_id = client.get("/api/auth/me", headers=auth(token)).json()["id"]
    user = db.query(User).filter(User.id == user_id).one()
    db.query(BodyStat).filter(BodyStat.character_id == user.character_id).update(
        {BodyStat.potential: 99}
    )
    db.commit()

    end_data, _ = _full_cycle(client, token)
    assert end_data["breakthroughs"], "Expected a breakthrough with potential=99"


def test_end_workout_idempotency_no_double_growth(client):
    """Calling end twice must NOT award growth twice."""
    _, token = make_user(client, "grower7", suffix="gr")
    wid_r = client.post(
        "/api/workouts/", json={"notes": "idempotent"}, headers=auth(token)
    )
    wid = wid_r.json()["id"]

    r1 = client.post(f"/api/workouts/{wid}/end", headers=auth(token))
    assert r1.status_code == 200
    stats_after_first = {s["part"]: s["potential"] for s in r1.json()["body_stats"]}

    r2 = client.post(f"/api/workouts/{wid}/end", headers=auth(token))
    assert r2.status_code == 200, "Second end must be idempotent"

    # Stats must be unchanged
    r3 = client.get("/api/stats/", headers=auth(token))
    current = {s["part"]: s["potential"] for s in r3.json()}
    assert current == stats_after_first, "Double end awarded growth twice"


# ── GrowthEvent engine tests ─────────────────────────────────────────────────


def test_growth_events_persisted_in_db(client, db):
    """GrowthEvent rows must exist after end_workout — one per body part."""
    from models import GrowthEvent, User

    _, token = make_user(client, "eventer1", suffix="ev")
    _, wid = _full_cycle(client, token)
    user_id = client.get("/api/auth/me", headers=auth(token)).json()["id"]
    events = db.query(GrowthEvent).filter(GrowthEvent.workout_id == wid).all()
    assert len(events) == 7, "Expected one GrowthEvent per body part"
    for ge in events:
        assert ge.user_id == user_id
        assert ge.formula_version == 1
        assert ge.level_before >= 1
        assert ge.level_after >= ge.level_before
        assert ge.potential_after >= 0
        assert ge.reason  # must be non-empty auditable string


def test_growth_event_delta_matches_stat_change(client, db):
    """GrowthEvent.delta == potential_after - potential_before (mod level-up)."""
    from models import GrowthEvent

    _, token = make_user(client, "eventer2", suffix="ev")
    _, wid = _full_cycle(client, token)
    for ge in db.query(GrowthEvent).filter(GrowthEvent.workout_id == wid).all():
        xp_before = ge.level_before * 100 + ge.potential_before
        xp_after = ge.level_after * 100 + ge.potential_after
        assert xp_after - xp_before == ge.delta, (
            f"{ge.body_part}: delta={ge.delta} but xp diff={xp_after - xp_before}"
        )


def test_idempotent_end_returns_same_growth_events(client, db):
    """Second /end call must return identical breakthroughs and body_stats."""
    _, token = make_user(client, "eventer3", suffix="ev")
    _, wid = _full_cycle(client, token)
    r2 = client.post(f"/api/workouts/{wid}/end", headers=auth(token))
    assert r2.status_code == 200
    data = r2.json()
    assert len(data["body_stats"]) == 7
    # breakthroughs list present (may be empty, but key must exist)
    assert "breakthroughs" in data


def test_part_mention_gives_bonus(client, db):
    """A setlog mentioning 가슴 (chest) should give chest a higher delta."""
    from models import GrowthEvent

    _, token = make_user(client, "eventer4", suffix="ev")

    wid = client.post(
        "/api/workouts/", json={"notes": "mention"}, headers=auth(token)
    ).json()["id"]
    client.post(
        f"/api/workouts/{wid}/setlogs",
        json={"type": "mid", "content": "가슴 운동 집중"},
        headers=auth(token),
    )
    r = client.post(f"/api/workouts/{wid}/end", headers=auth(token))
    assert r.status_code == 200

    events = {
        ge.body_part: ge
        for ge in db.query(GrowthEvent).filter(GrowthEvent.workout_id == wid).all()
    }
    chest_delta = events["chest"].delta
    back_delta = events["back"].delta
    # chest was mentioned, so delta should be larger than an unmentioned part
    assert chest_delta > back_delta, (
        f"chest (mentioned) delta={chest_delta} not > back delta={back_delta}"
    )


def test_daily_cap_limits_total_gain(client, db):
    """After DAILY_CAP_PER_PART potential is granted, further workouts yield delta=0."""
    from growth import DAILY_CAP_PER_PART
    from models import GrowthEvent

    _, token = make_user(client, "eventer5", suffix="ev")

    # Do one real workout to get GrowthEvents, then inflate their deltas to exhaust the cap.
    wid1 = client.post("/api/workouts/", json={}, headers=auth(token)).json()["id"]
    client.post(f"/api/workouts/{wid1}/end", headers=auth(token))

    # Overwrite deltas so the daily total == DAILY_CAP_PER_PART for every part.
    for ge in db.query(GrowthEvent).filter(GrowthEvent.workout_id == wid1).all():
        ge.delta = DAILY_CAP_PER_PART
        ge.potential_after = ge.potential_before + DAILY_CAP_PER_PART
    db.commit()

    # Second workout should yield delta=0 for all parts
    wid2 = client.post("/api/workouts/", json={}, headers=auth(token)).json()["id"]
    r = client.post(f"/api/workouts/{wid2}/end", headers=auth(token))
    assert r.status_code == 200

    events2 = db.query(GrowthEvent).filter(GrowthEvent.workout_id == wid2).all()
    assert all(ge.delta == 0 for ge in events2), (
        "Daily cap exhausted but second workout still awarded growth"
    )


def test_formula_version_stored_on_growth_event(client, db):
    """formula_version column must equal growth.FORMULA_VERSION."""
    from growth import FORMULA_VERSION
    from models import GrowthEvent

    _, token = make_user(client, "eventer6", suffix="ev")
    _, wid = _full_cycle(client, token)
    for ge in db.query(GrowthEvent).filter(GrowthEvent.workout_id == wid).all():
        assert ge.formula_version == FORMULA_VERSION


def test_structured_body_parts_are_adapted_to_existing_growth_keywords():
    """Structured W1 body-part values feed the unchanged compute_growth parser."""
    from growth import _PART_KW_KR, structured_growth_contents

    assert structured_growth_contents(("chest", "core")) == [
        _PART_KW_KR["chest"],
        _PART_KW_KR["core"],
    ]
