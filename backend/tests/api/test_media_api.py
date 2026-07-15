"""API tests for /api/media — real upload, private access control, deletion."""
from tests.conftest import auth, make_user

PNG = b"\x89PNG\r\n\x1a\n" + b"fake-png-body"
JPEG = b"\xff\xd8\xff" + b"fake-jpeg-body"


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
