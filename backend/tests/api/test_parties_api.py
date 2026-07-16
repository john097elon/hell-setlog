"""API tests for /api/parties — join, capacity, membership, feed authorization."""

from tests.conftest import auth, make_user

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
    u2, t2 = make_user(client, "pguest1", suffix="pt")

    create_r = client.post(
        "/api/parties/", json={"name": "공개 파티"}, headers=auth(t1)
    )
    code = create_r.json()["invite_code"]

    r = client.post("/api/parties/join", json={"invite_code": code}, headers=auth(t2))
    assert r.status_code == 200
    members = r.json()["members"]
    guest_member = next(m for m in members if m["user_id"] == u2["id"])
    assert guest_member["status"] == "active"


def test_join_already_member_returns_409(client):
    _, token = make_user(client, "phost2", suffix="pt")
    create_r = client.post("/api/parties/", json={"name": "p2"}, headers=auth(token))
    code = create_r.json()["invite_code"]

    r = client.post(
        "/api/parties/join", json={"invite_code": code}, headers=auth(token)
    )
    assert r.status_code == 409


def test_join_nonexistent_code_returns_404(client):
    _, token = make_user(client, "phost3", suffix="pt")
    r = client.post(
        "/api/parties/join", json={"invite_code": "XXXXXX"}, headers=auth(token)
    )
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
    u2, t2 = make_user(client, "pkick1", suffix="pt")

    create_r = client.post(
        "/api/parties/", json={"name": "kick test"}, headers=auth(t1)
    )
    pid = create_r.json()["id"]
    code = create_r.json()["invite_code"]

    client.post(
        "/api/parties/join", json={"invite_code": code}, headers=auth(t2)
    )
    uid2 = u2["id"]

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


# ── Capacity & Reactions ─────────────────────────────────────────────────────


def test_join_party_full_returns_400(client):
    _, t1 = make_user(client, "phostfull", suffix="pt")
    create_r = client.post("/api/parties/", json={"name": "풀파티"}, headers=auth(t1))
    code = create_r.json()["invite_code"]

    # We need 3 more members to hit max_members = 4
    for i in range(3):
        _, t_guest = make_user(client, f"pguestfull{i}", suffix="pt")
        r = client.post("/api/parties/join", json={"invite_code": code}, headers=auth(t_guest))
        assert r.status_code == 200

    # The 5th member trying to join should get 400
    _, t_extra = make_user(client, "pguestextra", suffix="pt")
    r = client.post("/api/parties/join", json={"invite_code": code}, headers=auth(t_extra))
    assert r.status_code == 400
    assert r.json()["detail"] == "Party is full"


def test_reaction_permissions_and_duplication(client):
    # alice starts workout and setlog
    _, talice = make_user(client, "alice", suffix="re")
    create_r = client.post("/api/parties/", json={"name": "리액션파티"}, headers=auth(talice))
    pid = create_r.json()["id"]
    code = create_r.json()["invite_code"]

    # bob joins the party
    _, tbob = make_user(client, "bob", suffix="re")
    client.post("/api/parties/join", json={"invite_code": code}, headers=auth(tbob))

    # alice starts a workout in the party
    workout_r = client.post("/api/workouts/", json={"party_id": pid, "notes": "하체 조진다"}, headers=auth(talice))
    wid = workout_r.json()["id"]

    # bob can react to alice's workout in the party
    react_r = client.post("/api/reactions/", json={"target_type": "workout", "target_id": wid, "emoji": "🔥"}, headers=auth(tbob))
    assert react_r.status_code == 201
    rid = react_r.json()["id"]

    # bob cannot react with the same emoji twice (duplicate)
    react_r2 = client.post("/api/reactions/", json={"target_type": "workout", "target_id": wid, "emoji": "🔥"}, headers=auth(tbob))
    assert react_r2.status_code == 409

    # charlie (outsider) cannot react to alice's workout
    _, tcharlie = make_user(client, "charlie", suffix="re")
    react_r3 = client.post("/api/reactions/", json={"target_type": "workout", "target_id": wid, "emoji": "🔥"}, headers=auth(tcharlie))
    assert react_r3.status_code == 403

    # bob leaves the party
    client.delete(f"/api/parties/{pid}/leave", headers=auth(tbob))

    # bob (now outsider) cannot add reactions anymore
    react_r4 = client.post("/api/reactions/", json={"target_type": "workout", "target_id": wid, "emoji": "💪"}, headers=auth(tbob))
    assert react_r4.status_code == 403

    # bob cannot delete his own previous reaction anymore
    del_r = client.delete(f"/api/reactions/{rid}", headers=auth(tbob))
    assert del_r.status_code == 403


def test_party_feed_includes_video_media_metadata(client):
    owner, token = make_user(client, "feedvideo", suffix="pt")
    party = client.post(
        "/api/parties/", json={"name": "video feed"}, headers=auth(token)
    ).json()
    upload = client.post(
        "/api/media",
        data={"party_id": str(party["id"])},
        files={"file": ("clip.mp4", b"not-a-real-mp4", "video/mp4")},
        headers=auth(token),
    )
    assert upload.status_code == 201, upload.text
    key = upload.json()["key"]

    workout = client.post(
        "/api/workouts/", json={"party_id": party["id"]}, headers=auth(token)
    ).json()
    setlog = client.post(
        f"/api/workouts/{workout['id']}/setlogs",
        json={"type": "mid", "content": "", "file_path": key},
        headers=auth(token),
    )
    assert setlog.status_code == 201, setlog.text

    feed = client.get(f"/api/parties/{party['id']}/feed", headers=auth(token))
    assert feed.status_code == 200, feed.text
    event = next(item for item in feed.json() if item["id"] == f"setlog:{setlog.json()['id']}")
    expected_media = {
        "id": key,
        "poster_url": None,
        "duration_seconds": None,
        "size_bytes": len(b"not-a-real-mp4"),
    }
    assert event["media"] == expected_media
    assert event["data"]["media"] == expected_media
