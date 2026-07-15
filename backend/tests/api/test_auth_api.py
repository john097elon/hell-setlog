"""API tests for /api/auth endpoints."""

from tests.conftest import auth, make_user


def test_register_success(client):
    r = client.post(
        "/api/auth/register",
        json={
            "username": "alice",
            "email": "alice@test.com",
            "password": "pass1234",
        },
    )
    assert r.status_code == 201
    data = r.json()
    assert data["username"] == "alice"
    assert "password_hash" not in data


def test_register_duplicate_username(client):
    client.post(
        "/api/auth/register",
        json={"username": "bob", "email": "bob@test.com", "password": "pass1234"},
    )
    r = client.post(
        "/api/auth/register",
        json={"username": "bob", "email": "bob2@test.com", "password": "pass1234"},
    )
    assert r.status_code == 409


def test_register_duplicate_email(client):
    client.post(
        "/api/auth/register",
        json={"username": "carol", "email": "carol@test.com", "password": "pass1234"},
    )
    r = client.post(
        "/api/auth/register",
        json={"username": "carol2", "email": "carol@test.com", "password": "pass1234"},
    )
    assert r.status_code == 409


def test_login_by_username(client):
    client.post(
        "/api/auth/register",
        json={"username": "dave", "email": "dave@test.com", "password": "pass1234"},
    )
    r = client.post(
        "/api/auth/login", json={"username": "dave", "password": "pass1234"}
    )
    assert r.status_code == 200
    assert "access_token" in r.json()


def test_login_by_email(client):
    client.post(
        "/api/auth/register",
        json={"username": "eve", "email": "eve@test.com", "password": "pass1234"},
    )
    r = client.post(
        "/api/auth/login", json={"email": "eve@test.com", "password": "pass1234"}
    )
    assert r.status_code == 200


def test_login_wrong_password(client):
    client.post(
        "/api/auth/register",
        json={"username": "frank", "email": "frank@test.com", "password": "pass1234"},
    )
    r = client.post("/api/auth/login", json={"username": "frank", "password": "wrong"})
    assert r.status_code == 401


def test_me_returns_user(client):
    _, token = make_user(client, "grace")
    r = client.get("/api/auth/me", headers=auth(token))
    assert r.status_code == 200
    assert r.json()["username"] == "grace"


def test_me_unauthenticated(client):
    r = client.get("/api/auth/me")
    assert r.status_code == 401


def test_register_creates_7_body_stats(client):
    _, token = make_user(client, "hank")
    r = client.get("/api/stats/", headers=auth(token))
    assert r.status_code == 200
    parts = {s["part"] for s in r.json()}
    assert parts == {"chest", "back", "legs", "shoulders", "arms", "core", "stamina"}
