"""API tests for /api/media — real upload, private access control, deletion."""
from tests.conftest import auth, make_user

PNG = b"\x89PNG\r\n\x1a\n" + b"fake-png-body"
JPEG = b"\xff\xd8\xff" + b"fake-jpeg-body"
MP4 = b"not-a-real-mp4"


def _upload(client, token, name="p.png", body=PNG, content_type="image/png"):
    return client.post(
        "/api/media",
        files={"file": (name, body, content_type)},
        headers=auth(token),
    )


def test_upload_returns_owned_key(client):
    user, token = make_user(client, "media1", suffix="md")
    r = _upload(client, token)
    assert r.status_code == 201, r.text
    key = r.json()["key"]
    assert key.startswith(f"users/{user['id']}/")
    assert key.endswith(".png")


def test_upload_rejects_non_image(client):
    _, token = make_user(client, "media2", suffix="md")
    r = _upload(client, token, name="x.png", body=b"not an image at all", content_type="image/png")
    assert r.status_code == 422


def test_upload_sniffs_type_over_declared(client):
    """A JPEG mislabelled as png is stored as jpeg (type derived from bytes)."""
    _, token = make_user(client, "media3", suffix="md")
    r = _upload(client, token, name="x.png", body=JPEG, content_type="image/png")
    assert r.status_code == 201
    assert r.json()["key"].endswith(".jpg")
    assert r.json()["content_type"] == "image/jpeg"


def test_owner_can_get_media(client):
    _, token = make_user(client, "media4", suffix="md")
    key = _upload(client, token).json()["key"]
    r = client.get(f"/api/media/{key}", headers=auth(token))
    assert r.status_code == 200
    assert r.content == PNG
    assert r.headers["content-type"].startswith("image/png")


def test_non_owner_cannot_get_media(client):
    _, t1 = make_user(client, "media5a", suffix="md")
    _, t2 = make_user(client, "media5b", suffix="md")
    key = _upload(client, t1).json()["key"]
    r = client.get(f"/api/media/{key}", headers=auth(t2))
    assert r.status_code == 404


def test_get_media_requires_auth(client):
    _, token = make_user(client, "media6", suffix="md")
    key = _upload(client, token).json()["key"]
    r = client.get(f"/api/media/{key}")
    assert r.status_code == 401


def test_owner_can_delete_media(client):
    _, token = make_user(client, "media7", suffix="md")
    key = _upload(client, token).json()["key"]
    r = client.delete(f"/api/media/{key}", headers=auth(token))
    assert r.status_code == 204
    assert client.get(f"/api/media/{key}", headers=auth(token)).status_code == 404


def test_non_owner_cannot_delete_media(client):
    _, t1 = make_user(client, "media8a", suffix="md")
    _, t2 = make_user(client, "media8b", suffix="md")
    key = _upload(client, t1).json()["key"]
    assert client.delete(f"/api/media/{key}", headers=auth(t2)).status_code == 404
    # object survives
    assert client.get(f"/api/media/{key}", headers=auth(t1)).status_code == 200


def test_party_member_can_upload_video_and_get_playback_url(client):
    owner, token = make_user(client, "video1", suffix="md")
    party_id = _create_party(client, token)

    upload = _upload_video(client, token, party_id)

    assert upload.status_code == 201, upload.text
    payload = upload.json()
    assert payload["key"].startswith(f"users/{owner['id']}/")
    assert payload["key"].endswith(".mp4")
    assert payload["content_type"] == "video/mp4"
    assert payload["duration_seconds"] is None
    assert payload["status"] == "ready"

    playback = client.get(f"/api/media/{payload['key']}/playback", headers=auth(token))
    assert playback.status_code == 200, playback.text
    assert playback.json()["expires_in_seconds"] == 300


def test_video_upload_rejects_wrong_type_and_oversize_body(client):
    _, token = make_user(client, "video2", suffix="md")
    party_id = _create_party(client, token)

    wrong_type = _upload_video(client, token, party_id, content_type="video/quicktime")
    assert wrong_type.status_code == 422
    assert wrong_type.json()["error"]["code"] == "unsupported_media_type"

    too_large = _upload_video(client, token, party_id, body=b"x" * (10 * 1024 * 1024 + 1))
    assert too_large.status_code == 422
    assert too_large.json()["error"]["code"] == "file_too_large"


def _create_party(client, token):
    response = client.post(
        "/api/parties/", json={"name": "video party"}, headers=auth(token)
    )
    assert response.status_code == 201, response.text
    return response.json()["id"]


def _upload_video(client, token, party_id, body=MP4, content_type="video/mp4"):
    return client.post(
        "/api/media",
        data={"party_id": str(party_id)},
        files={"file": ("clip.mp4", body, content_type)},
        headers=auth(token),
    )


def test_playback_allows_active_party_members_and_forbids_inactive_members(client):
    _, owner_token = make_user(client, "video3owner", suffix="md")
    party_response = client.post(
        "/api/parties/", json={"name": "shared video"}, headers=auth(owner_token)
    )
    party = party_response.json()
    _, guest_token = make_user(client, "video3guest", suffix="md")
    joined = client.post(
        "/api/parties/join",
        json={"invite_code": party["invite_code"]},
        headers=auth(guest_token),
    )
    assert joined.status_code == 200, joined.text

    upload = _upload_video(client, owner_token, party["id"])
    key = upload.json()["key"]
    workout = client.post(
        "/api/workouts/", json={"party_id": party["id"]}, headers=auth(owner_token)
    ).json()
    attached = client.post(
        f"/api/workouts/{workout['id']}/setlogs",
        json={"type": "mid", "content": "", "file_path": key},
        headers=auth(owner_token),
    )
    assert attached.status_code == 201, attached.text

    assert client.get(f"/api/media/{key}/playback", headers=auth(guest_token)).status_code == 200
    assert client.delete(
        f"/api/parties/{party['id']}/leave", headers=auth(guest_token)
    ).status_code == 204
    assert client.get(f"/api/media/{key}/playback", headers=auth(guest_token)).status_code == 403
