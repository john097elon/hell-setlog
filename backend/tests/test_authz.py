"""Authorization and security regression tests — ELO-16.

Covers: BOLA on workout/setlog, stats PATCH removal, registration
enumeration defense, duplicate end idempotency.
"""
import pytest
from fastapi.testclient import TestClient

from tests.conftest import auth_headers, register_and_login

# ── BOLA: workout ownership ─────────────────────────────────────────────────

def test_get_workout_owner_allowed(client):
    token = register_and_login(client, "alice")
    resp = client.post("/api/workouts/", json={}, headers=auth_headers(token))
    assert resp.status_code == 201
    wid = resp.json()["id"]

    resp = client.get(f"/api/workouts/{wid}", headers=auth_headers(token))
    assert resp.status_code == 200


def test_get_workout_outsider_gets_404(client):
    alice_token = register_and_login(client, "alice")
    bob_token = register_and_login(client, "bob")

    resp = client.post("/api/workouts/", json={}, headers=auth_headers(alice_token))
    assert resp.status_code == 201
    wid = resp.json()["id"]

    # Bob must not see Alice's workout — 404, not 403 (prevents ID enumeration)
    resp = client.get(f"/api/workouts/{wid}", headers=auth_headers(bob_token))
    assert resp.status_code == 404


# ── BOLA: setlog ownership ──────────────────────────────────────────────────

def test_list_setlogs_owner_allowed(client):
    token = register_and_login(client, "alice")
    resp = client.post("/api/workouts/", json={}, headers=auth_headers(token))
    wid = resp.json()["id"]

    resp = client.get(f"/api/workouts/{wid}/setlogs", headers=auth_headers(token))
    assert resp.status_code == 200


def test_list_setlogs_outsider_gets_404(client):
    alice_token = register_and_login(client, "alice")
    bob_token = register_and_login(client, "bob")

    resp = client.post("/api/workouts/", json={}, headers=auth_headers(alice_token))
    wid = resp.json()["id"]

    resp = client.get(f"/api/workouts/{wid}/setlogs", headers=auth_headers(bob_token))
    assert resp.status_code == 404


# ── PATCH /stats/{part} removed ────────────────────────────────────────────

def test_stats_patch_removed(client):
    token = register_and_login(client, "alice")
    resp = client.patch("/api/stats/chest", json={"level": 99}, headers=auth_headers(token))
    # Route no longer registered → 405 or 404
    assert resp.status_code in (404, 405)


def test_stats_get_still_works(client):
    token = register_and_login(client, "alice")
    resp = client.get("/api/stats/", headers=auth_headers(token))
    assert resp.status_code == 200


# ── Registration enumeration defense ────────────────────────────────────────

def test_register_duplicate_username_generic_error(client):
    client.post("/api/auth/register", json={
        "username": "alice", "email": "alice@example.com", "password": "pass1234"
    })
    resp = client.post("/api/auth/register", json={
        "username": "alice", "email": "other@example.com", "password": "pass1234"
    })
    assert resp.status_code == 409
    # Must not reveal which field caused the conflict
    detail = resp.json()["detail"].lower()
    assert "username" not in detail
    assert "email" not in detail


def test_register_duplicate_email_generic_error(client):
    client.post("/api/auth/register", json={
        "username": "alice", "email": "alice@example.com", "password": "pass1234"
    })
    resp = client.post("/api/auth/register", json={
        "username": "differentuser", "email": "alice@example.com", "password": "pass1234"
    })
    assert resp.status_code == 409
    detail = resp.json()["detail"].lower()
    assert "username" not in detail
    assert "email" not in detail


# ── Login error: generic message ────────────────────────────────────────────

def test_login_wrong_password_generic_error(client):
    client.post("/api/auth/register", json={
        "username": "alice", "email": "alice@example.com", "password": "pass1234"
    })
    resp = client.post("/api/auth/login", json={"username": "alice", "password": "wrong"})
    assert resp.status_code == 401
    detail = resp.json()["detail"].lower()
    assert "password" not in detail
    assert "username" not in detail


def test_login_nonexistent_user_generic_error(client):
    resp = client.post("/api/auth/login", json={"username": "ghost", "password": "pass"})
    assert resp.status_code == 401
    detail = resp.json()["detail"].lower()
    assert "password" not in detail
    assert "username" not in detail


# ── Workout end: idempotency ────────────────────────────────────────────────

def test_end_workout_idempotent(client):
    token = register_and_login(client, "alice")
    resp = client.post("/api/workouts/", json={}, headers=auth_headers(token))
    wid = resp.json()["id"]

    resp1 = client.post(f"/api/workouts/{wid}/end", headers=auth_headers(token))
    assert resp1.status_code == 200

    # Second call must succeed (200), not fail with 400
    resp2 = client.post(f"/api/workouts/{wid}/end", headers=auth_headers(token))
    assert resp2.status_code == 200


def test_end_workout_outsider_gets_404(client):
    alice_token = register_and_login(client, "alice")
    bob_token = register_and_login(client, "bob")

    resp = client.post("/api/workouts/", json={}, headers=auth_headers(alice_token))
    wid = resp.json()["id"]

    resp = client.post(f"/api/workouts/{wid}/end", headers=auth_headers(bob_token))
    assert resp.status_code == 404


# ── PATCH workout: status field ignored (server-managed state machine) ──────

def test_patch_workout_notes_only(client):
    token = register_and_login(client, "alice")
    resp = client.post("/api/workouts/", json={}, headers=auth_headers(token))
    wid = resp.json()["id"]

    # Notes update must work
    resp = client.patch(f"/api/workouts/{wid}", json={"notes": "good session"},
                        headers=auth_headers(token))
    assert resp.status_code == 200
    assert resp.json()["notes"] == "good session"


def test_patch_workout_status_ignored(client):
    token = register_and_login(client, "alice")
    resp = client.post("/api/workouts/", json={}, headers=auth_headers(token))
    wid = resp.json()["id"]

    # Attempting to set status via PATCH must not change it
    resp = client.patch(f"/api/workouts/{wid}", json={"status": "ended"},
                        headers=auth_headers(token))
    assert resp.status_code == 200
    assert resp.json()["status"] == "active"


# ── Growth is deterministic (no randomness) ─────────────────────────────────

def test_end_workout_growth_deterministic(client):
    token = register_and_login(client, "alice")
    resp = client.post("/api/workouts/", json={}, headers=auth_headers(token))
    wid = resp.json()["id"]

    resp = client.post(f"/api/workouts/{wid}/end", headers=auth_headers(token))
    assert resp.status_code == 200
    stats = resp.json()["body_stats"]
    # All parts must receive the same base gain (deterministic formula)
    potentials = [s["potential"] for s in stats]
    assert len(set(potentials)) == 1, "Non-deterministic growth: parts received different gains"
