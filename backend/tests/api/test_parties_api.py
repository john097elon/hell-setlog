"""API tests for /api/parties — join, capacity, membership, feed authorization."""
from tests.conftest import make_user, auth


# ── Create & join ────────────────────────────────────────────────────────────

def test_create_party(client):
    _, token = make_user(client, "pcreator1", suffix="pt")
    r = client.post("/api/parties/", json={"name": "테스트 파티"}, headers=auth(token))
    assert r.status_code == 201
    data = r.json()
    assert data["name"] == "테스트 파티"
    assert data["invite_code"]
    assert data["member_count"] == 1


def test_join_party_by_invite_code(client):
    _, t1 = make_user(client, "phost1", suffix="pt")
    _, t2 = make_user(client, "pguest1", suffix="pt")

    create_r = client.post("/api/parties/", json={"name": "공개 파티"}, headers=auth(t1))
    code = create_r.json()["invite_code"]

    r = client.post("/api/parties/join", json={"invite_code": code}, headers=auth(t2))
    assert r.status_code == 200
    assert r.json()["status"] == "active"


def test_join_already_member_returns_409(client):
    _, token = make_user(client, "phost2", suffix="pt")
    create_r = client.post("/api/parties/", json={"name": "p2"}, headers=auth(token))
    code = create_r.json()["invite_code"]

    r = client.post("/api/parties/join", json={"invite_code": code}, headers=auth(token))
    assert r.status_code == 409


def test_join_nonexistent_code_returns_404(client):
    _, token = make_user(client, "phost3", suffix="pt")
    r = client.post("/api/parties/join", json={"invite_code": "XXXXXX"}, headers=auth(token))
    assert r.status_code == 404


# ── Membership authorization ─────────────────────────────────────────────────

def test_non_member_cannot_view_party(client):
    _, t1 = make_user(client, "phost4", suffix="pt")
    _, t2 = make_user(client, "pout1", suffix="pt")
    create_r = client.post("/api/parties/", json={"name": "private"}, headers=auth(t1))
    pid = create_r.json()["id"]

    r = client.get(f"/api/parties/{pid}", headers=auth(t2))
    assert r.status_code == 403


def test_non_member_cannot_view_feed(client):
    _, t1 = make_user(client, "phost5", suffix="pt")
    _, t2 = make_user(client, "pout2", suffix="pt")
    create_r = client.post("/api/parties/", json={"name": "private2"}, headers=auth(t1))
    pid = create_r.json()["id"]

    r = client.get(f"/api/parties/{pid}/feed", headers=auth(t2))
    assert r.status_code == 403


# ── Leave & re-join ──────────────────────────────────────────────────────────

def test_leave_and_rejoin(client):
    _, t1 = make_user(client, "phost6", suffix="pt")
    _, t2 = make_user(client, "pguest2", suffix="pt")

    create_r = client.post("/api/parties/", json={"name": "rejoin"}, headers=auth(t1))
    pid = create_r.json()["id"]
    code = create_r.json()["invite_code"]

    client.post("/api/parties/join", json={"invite_code": code}, headers=auth(t2))
    client.delete(f"/api/parties/{pid}/leave", headers=auth(t2))

    r = client.post("/api/parties/join", json={"invite_code": code}, headers=auth(t2))
    assert r.status_code == 200


# ── Kicked member cannot rejoin ──────────────────────────────────────────────

def test_kicked_member_cannot_rejoin(client):
    _, t1 = make_user(client, "phost7", suffix="pt")
    _, t2 = make_user(client, "pkick1", suffix="pt")

    create_r = client.post("/api/parties/", json={"name": "kick test"}, headers=auth(t1))
    pid = create_r.json()["id"]
    code = create_r.json()["invite_code"]

    join_r = client.post("/api/parties/join", json={"invite_code": code}, headers=auth(t2))
    uid2 = join_r.json()["user_id"]

    client.delete(f"/api/parties/{pid}/members/{uid2}", headers=auth(t1))

    r = client.post("/api/parties/join", json={"invite_code": code}, headers=auth(t2))
    assert r.status_code == 403


# ── List only own parties ────────────────────────────────────────────────────

def test_list_parties_only_own(client):
    _, t1 = make_user(client, "phost8", suffix="pt")
    _, t2 = make_user(client, "pother1", suffix="pt")
    client.post("/api/parties/", json={"name": "t1 party"}, headers=auth(t1))

    r = client.get("/api/parties/", headers=auth(t2))
    assert r.status_code == 200
    assert r.json() == []
