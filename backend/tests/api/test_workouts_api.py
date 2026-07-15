"""API tests for /api/workouts — including BOLA authorization regression suite.

Tests marked with BOLA: document the CORRECT expected behavior (403/404 for
non-owners). These tests WILL FAIL until the security fix (Stage 2 authz PR)
is merged. They are intentionally written to drive TDD for the fix.
"""
import pytest
from tests.conftest import make_user, auth


# ── Helpers ─────────────────────────────────────────────────────────────────

def _start_workout(client, token, party_id=None):
    body = {"notes": "test"} if party_id is None else {"party_id": party_id, "notes": "test"}
    r = client.post("/api/workouts/", json=body, headers=auth(token))
    assert r.status_code == 201
    return r.json()["id"]


# ── Ownership ────────────────────────────────────────────────────────────────

def test_list_workouts_only_own(client):
    _, t1 = make_user(client, "u1", suffix="wk")
    _, t2 = make_user(client, "u2", suffix="wk")
    _start_workout(client, t1)
    r = client.get("/api/workouts/", headers=auth(t2))
    assert r.status_code == 200
    assert r.json() == []


# BOLA: GET /workouts/{id} must check ownership
def test_get_workout_forbidden_for_non_owner(client):
    _, t1 = make_user(client, "owner1", suffix="wk")
    _, t2 = make_user(client, "other1", suffix="wk")
    wid = _start_workout(client, t1)
    r = client.get(f"/api/workouts/{wid}", headers=auth(t2))
    assert r.status_code in (403, 404), (
        f"BOLA: non-owner got {r.status_code} on GET /workouts/{{id}} — "
        "ownership check missing in workouts.py:get_workout"
    )


# BOLA: GET /workouts/{id}/setlogs must check ownership
def test_list_setlogs_forbidden_for_non_owner(client):
    _, t1 = make_user(client, "owner2", suffix="wk")
    _, t2 = make_user(client, "other2", suffix="wk")
    wid = _start_workout(client, t1)
    r = client.get(f"/api/workouts/{wid}/setlogs", headers=auth(t2))
    assert r.status_code in (403, 404), (
        f"BOLA: non-owner got {r.status_code} on GET /workouts/{{id}}/setlogs — "
        "ownership check missing in workouts.py:list_setlogs"
    )


def test_update_workout_forbidden_for_non_owner(client):
    _, t1 = make_user(client, "owner3", suffix="wk")
    _, t2 = make_user(client, "other3", suffix="wk")
    wid = _start_workout(client, t1)
    r = client.patch(f"/api/workouts/{wid}", json={"notes": "hacked"}, headers=auth(t2))
    assert r.status_code == 403


def test_end_workout_forbidden_for_non_owner(client):
    _, t1 = make_user(client, "owner4", suffix="wk")
    _, t2 = make_user(client, "other4", suffix="wk")
    wid = _start_workout(client, t1)
    r = client.post(f"/api/workouts/{wid}/end", headers=auth(t2))
    assert r.status_code == 403


def test_add_setlog_forbidden_for_non_owner(client):
    _, t1 = make_user(client, "owner5", suffix="wk")
    _, t2 = make_user(client, "other5", suffix="wk")
    wid = _start_workout(client, t1)
    r = client.post(f"/api/workouts/{wid}/setlogs",
                    json={"type": "mid", "content": "steal"},
                    headers=auth(t2))
    assert r.status_code == 403


# ── Workout end / idempotency ────────────────────────────────────────────────

def test_end_workout_returns_body_stats(client):
    _, token = make_user(client, "ender1", suffix="wk")
    wid = _start_workout(client, token)
    r = client.post(f"/api/workouts/{wid}/end", headers=auth(token))
    assert r.status_code == 200
    data = r.json()
    assert "body_stats" in data
    assert len(data["body_stats"]) == 7


def test_end_workout_idempotency(client):
    """Calling end twice must return 400 on the second call — no double growth."""
    _, token = make_user(client, "ender2", suffix="wk")
    wid = _start_workout(client, token)
    r1 = client.post(f"/api/workouts/{wid}/end", headers=auth(token))
    assert r1.status_code == 200
    r2 = client.post(f"/api/workouts/{wid}/end", headers=auth(token))
    assert r2.status_code == 400, "Second end call must be rejected (idempotency)"


def test_ended_workout_persists_on_refresh(client):
    """GET after end must show status=ended and an ended_at timestamp."""
    _, token = make_user(client, "ender3", suffix="wk")
    wid = _start_workout(client, token)
    client.post(f"/api/workouts/{wid}/end", headers=auth(token))
    r = client.get(f"/api/workouts/{wid}", headers=auth(token))
    assert r.status_code == 200
    data = r.json()
    assert data["status"] == "ended"
    assert data["ended_at"] is not None


def test_end_workout_404_for_unknown(client):
    _, token = make_user(client, "ender4", suffix="wk")
    r = client.post("/api/workouts/99999/end", headers=auth(token))
    assert r.status_code == 404


# ── Upload failure: file_path field (upload UI only, no file) ────────────────

def test_setlog_without_file_path_accepted(client):
    _, token = make_user(client, "uploader1", suffix="wk")
    wid = _start_workout(client, token)
    r = client.post(f"/api/workouts/{wid}/setlogs",
                    json={"type": "mid", "content": "no file"},
                    headers=auth(token))
    assert r.status_code == 201
    assert r.json()["file_path"] is None


def test_setlog_invalid_type_rejected(client):
    _, token = make_user(client, "uploader2", suffix="wk")
    wid = _start_workout(client, token)
    r = client.post(f"/api/workouts/{wid}/setlogs",
                    json={"type": "invalid", "content": "bad"},
                    headers=auth(token))
    assert r.status_code == 422
