import importlib
import importlib.util
from pathlib import Path
from urllib.parse import parse_qs, urlparse

import pytest

from settings import Settings


def storage_module():
    assert importlib.util.find_spec("storage") is not None, "storage module must exist"
    return importlib.import_module("storage")


@pytest.mark.parametrize(
    "content_type",
    ["text/html", "image/svg+xml", "application/octet-stream"],
)
def test_policy_rejects_unapproved_content_type(content_type):
    storage = storage_module()

    with pytest.raises(storage.StoragePolicyError, match="content type"):
        storage.StoragePolicy(max_bytes=10_000_000).validate(content_type, 1)


def test_policy_rejects_objects_over_limit():
    storage = storage_module()

    with pytest.raises(storage.StoragePolicyError, match="size"):
        storage.StoragePolicy(max_bytes=100).validate("image/jpeg", 101)


@pytest.mark.parametrize(
    "key",
    ["", "/users/1/a.jpg", "../a.jpg", "users/../a.jpg", "users//a.jpg", r"users\a.jpg"],
)
def test_policy_rejects_nonopaque_or_traversal_key(key):
    storage = storage_module()

    with pytest.raises(storage.StoragePolicyError, match="object key"):
        storage.StoragePolicy(max_bytes=100).validate_key(key)


def test_memory_storage_enforces_contract_and_five_minute_url():
    storage = storage_module()
    backend = storage.MemoryObjectStorage(storage.StoragePolicy(max_bytes=100))
    key = storage.generate_object_key(owner_id=7, content_type="image/jpeg")

    metadata = backend.put(key, b"jpeg-bytes", "image/jpeg")
    signed = backend.signed_get_url(key)

    assert key.startswith("users/7/")
    assert key.endswith(".jpg")
    assert metadata.size_bytes == len(b"jpeg-bytes")
    assert signed.key == key
    assert signed.expires_seconds == 300
    assert backend.head(key) == metadata
    backend.delete(key)
    with pytest.raises(storage.ObjectNotFound):
        backend.head(key)


def test_s3_presign_is_single_object_and_exactly_five_minutes():
    storage = storage_module()
    settings = Settings(
        _env_file=None,
        app_env="development",
        database_url="sqlite://",
        storage_backend="s3",
        storage_bucket="private-test",
        storage_region="us-east-1",
        storage_endpoint_url="http://object-storage:9000",
        storage_access_key="access",
        storage_secret_key="secret",
    )
    backend = storage.create_object_storage(settings)
    signed = backend.signed_get_url("users/7/object.jpg")

    query = parse_qs(urlparse(signed.url).query)
    assert signed.key == "users/7/object.jpg"
    assert signed.expires_seconds == 300
    assert query["X-Amz-Expires"] == ["300"]
    assert "private-test" in signed.url
    assert "users/7/object.jpg" in signed.url


def test_application_does_not_mount_public_upload_directory():
    source = Path("backend/main.py").read_text(encoding="utf-8")

    assert "StaticFiles" not in source
    assert 'app.mount("/uploads"' not in source
