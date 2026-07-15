"""API tests for the ELO-13 Workout/Setlog domain rules:
one-active policy, cancel transition, photo-only setlogs, media attachment authz.
"""
from tests.conftest import auth, make_user

PNG = b"\x89PNG\r\n\x1a\n" + b"fake-png-body"


def _start(client, token):
    r = client.post("/api/workouts/", json={"notes": "t"}, headers=auth(token))
    assert r.status_code == 201, r.text
    return r.json()["id"]


def _upload(client, token):
    r = client.post(
        "/api/media",
        files={"file": ("p.png", PNG, "image/png")},
        headers=auth(token),
    )
    assert r.status_code == 201, r.text
    return r.json()["key"]


# ── One active workout policy ────────────────────────────────────────────────

def test_second_active_workout_rejected(client):
    _, token = make_user(client, "dom1", suffix="dm")
    first = _start(client, token)
    r = client.post("/api/workouts/", json={"notes": "again"}, headers=auth(token))
    assert r.status_code == 409
    assert r.json()["detail"]["active_workout_id"] == first


def test_new_workout_allowed_after_end(client):
    _, token = make_user(client, "dom2", suffix="dm")
    wid = _start(client, token)
    client.post(f"/api/workouts/{wid}/end", headers=auth(token))
    r = client.post("/api/workouts/", json={"notes": "next"}, headers=auth(token))
    assert r.status_code == 201


def test_new_workout_allowed_after_cancel(client):
    _, token = make_user(client, "dom3", suffix="dm")
    wid = _start(client, token)
    c = client.post(f"/api/workouts/{wid}/cancel", headers=auth(token))
    assert c.status_code == 200
    assert c.json()["status"] == "cancelled"
    r = client.post("/api/workouts/", json={"notes": "next"}, headers=auth(token))
    assert r.status_code == 201


# ── Cancel transition ────────────────────────────────────────────────────────

def test_cancel_is_idempotent(client):
    _, token = make_user(client, "dom4", suffix="dm")
    wid = _start(client, token)
    client.post(f"/api/workouts/{wid}/cancel", headers=auth(token))
    r = client.post(f"/api/workouts/{wid}/cancel", headers=auth(token))
    assert r.status_code == 200
    assert r.json()["status"] == "cancelled"


def test_cannot_cancel_ended_workout(client):
    _, token = make_user(client, "dom5", suffix="dm")
    wid = _start(client, token)
    client.post(f"/api/workouts/{wid}/end", headers=auth(token))
    r = client.post(f"/api/workouts/{wid}/cancel", headers=auth(token))
    assert r.status_code == 409


def test_cancel_forbidden_for_non_owner(client):
    _, t1 = make_user(client, "dom6a", suffix="dm")
    _, t2 = make_user(client, "dom6b", suffix="dm")
    wid = _start(client, t1)
    assert client.post(f"/api/workouts/{wid}/cancel", headers=auth(t2)).status_code == 404


# ── Setlog content / media contract ──────────────────────────────────────────

def test_photo_only_setlog_accepted(client):
    _, token = make_user(client, "dom7", suffix="dm")
    wid = _start(client, token)
    key = _upload(client, token)
    r = client.post(
        f"/api/workouts/{wid}/setlogs",
        json={"type": "mid", "content": "", "file_path": key},
        headers=auth(token),
    )
    assert r.status_code == 201, r.text
    assert r.json()["file_path"] == key


def test_empty_setlog_rejected(client):
    _, token = make_user(client, "dom8", suffix="dm")
    wid = _start(client, token)
    r = client.post(
        f"/api/workouts/{wid}/setlogs",
        json={"type": "mid", "content": "   "},
        headers=auth(token),
    )
    assert r.status_code == 422


def test_cannot_attach_foreign_media(client):
    _, t1 = make_user(client, "dom9a", suffix="dm")
    _, t2 = make_user(client, "dom9b", suffix="dm")
    foreign_key = _upload(client, t1)
    wid = _start(client, t2)
    r = client.post(
        f"/api/workouts/{wid}/setlogs",
        json={"type": "mid", "content": "steal", "file_path": foreign_key},
        headers=auth(t2),
    )
    assert r.status_code == 403


def test_cannot_attach_missing_media(client):
    user, token = make_user(client, "dom10", suffix="dm")
    wid = _start(client, token)
    r = client.post(
        f"/api/workouts/{wid}/setlogs",
        json={"type": "mid", "content": "", "file_path": f"users/{user['id']}/deadbeef.png"},
        headers=auth(token),
    )
    assert r.status_code == 422


def test_cannot_log_to_ended_workout(client):
    _, token = make_user(client, "dom11", suffix="dm")
    wid = _start(client, token)
    client.post(f"/api/workouts/{wid}/end", headers=auth(token))
    r = client.post(
        f"/api/workouts/{wid}/setlogs",
        json={"type": "mid", "content": "late"},
        headers=auth(token),
    )
    assert r.status_code == 409
