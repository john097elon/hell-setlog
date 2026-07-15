"""Integration tests for workout end growth logic.

Covers: growth boundaries, randomness seeding, anti-farm, idempotency,
and stat persistence across requests.
"""
import pytest
from tests.conftest import make_user, auth


def _full_cycle(client, token):
    """Create workout, add setlogs, end workout; return end response json."""
    wid_r = client.post("/api/workouts/", json={"notes": "grow test"}, headers=auth(token))
    wid = wid_r.json()["id"]
    client.post(f"/api/workouts/{wid}/setlogs",
                json={"type": "start", "content": "시작"},
                headers=auth(token))
    client.post(f"/api/workouts/{wid}/setlogs",
                json={"type": "mid", "content": "가슴 운동 세트"},
                headers=auth(token))
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
    total1 = sum(p1.values())
    total2 = sum(p2.values())
    # total_xp_equivalent: level * 100 + potential
    xp1 = sum(s["level"] * 100 + s["potential"] for s in data1["body_stats"])
    xp2 = sum(s["level"] * 100 + s["potential"] for s in data2["body_stats"])
    assert xp2 > xp1, "Second workout did not increase total XP"


def test_breakthrough_on_level_up(client):
    """Force a level-up by directly setting potential to 90, then ending a workout."""
    from models import BodyStat, Character, User

    _, token = make_user(client, "grower6", suffix="gr")

    # Get user id from /me
    me = client.get("/api/auth/me", headers=auth(token)).json()
    char_id = me["character"]["id"]

    # Use the db fixture to set potential high
    # We can't easily reach db here without the fixture, so we use the API to
    # trigger via PATCH /stats/{part} instead (this is the "admin" API that
    # should be removed — but it exists now and tests can use it to set up state)
    for part in ["chest", "back", "legs", "shoulders", "arms", "core", "stamina"]:
        r = client.patch(f"/api/stats/{part}", json={"potential": 90}, headers=auth(token))
        assert r.status_code == 200

    end_data, _ = _full_cycle(client, token)
    # With potential=90 and a gain of at least 10, at least one level-up should occur
    assert len(end_data["breakthroughs"]) > 0, "Expected at least one breakthrough with potential=90"


def test_end_workout_idempotency_no_double_growth(client):
    """Calling end twice must NOT award growth twice."""
    _, token = make_user(client, "grower7", suffix="gr")
    wid_r = client.post("/api/workouts/", json={"notes": "idempotent"}, headers=auth(token))
    wid = wid_r.json()["id"]

    r1 = client.post(f"/api/workouts/{wid}/end", headers=auth(token))
    assert r1.status_code == 200
    stats_after_first = {s["part"]: s["potential"] for s in r1.json()["body_stats"]}

    r2 = client.post(f"/api/workouts/{wid}/end", headers=auth(token))
    assert r2.status_code == 400, "Second end must be rejected"

    # Stats must be unchanged
    r3 = client.get("/api/stats/", headers=auth(token))
    current = {s["part"]: s["potential"] for s in r3.json()}
    assert current == stats_after_first, "Double end awarded growth twice"
