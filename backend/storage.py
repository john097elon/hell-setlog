"""Private object-storage contract and environment adapters."""

from __future__ import annotations

import hashlib
import mimetypes
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Protocol
from urllib.parse import quote
from uuid import uuid4

import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError

from settings import Settings

ALLOWED_IMAGE_TYPES = frozenset({"image/jpeg", "image/png", "image/webp"})
ALLOWED_VIDEO_TYPES = frozenset({"video/mp4"})
ALLOWED_MEDIA_TYPES = ALLOWED_IMAGE_TYPES | ALLOWED_VIDEO_TYPES
EXTENSIONS = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "video/mp4": ".mp4",
}
SIGNED_URL_SECONDS = 300

# Magic-byte signatures — the stored content type is derived from the bytes,
# not the client-declared type, so a mislabelled or non-image payload is rejected.
_IMAGE_SIGNATURES = (
    (b"\xff\xd8\xff", "image/jpeg"),
    (b"\x89PNG\r\n\x1a\n", "image/png"),
)


def sniff_image_content_type(body: bytes) -> str | None:
    """Return the allowed image content type for the bytes, or None if unknown."""
    for signature, content_type in _IMAGE_SIGNATURES:
        if body.startswith(signature):
            return content_type
    if body[:4] == b"RIFF" and body[8:12] == b"WEBP":
        return "image/webp"
    return None


class StorageError(RuntimeError):
    """Base class for provider-independent storage failures."""


class StoragePolicyError(StorageError):
    """The object violates the upload/storage policy."""


class StorageUnavailable(StorageError):
    """The backing provider is unavailable without exposing provider details."""


class ObjectNotFound(StorageError):
    """The requested private object does not exist."""


@dataclass(frozen=True)
class ObjectMetadata:
    key: str
    content_type: str
    size_bytes: int
    checksum_sha256: str
    etag: str | None = None


@dataclass(frozen=True)
class SignedObjectUrl:
    url: str
    key: str
    expires_seconds: int
    expires_at: datetime


@dataclass(frozen=True)
class StoragePolicy:
    max_bytes: int
    allowed_content_types: frozenset[str] = ALLOWED_MEDIA_TYPES

    def validate(self, content_type: str, size_bytes: int) -> None:
        if content_type not in self.allowed_content_types:
            raise StoragePolicyError("content type is not allowed")
        if size_bytes < 1 or size_bytes > self.max_bytes:
            raise StoragePolicyError("object size is outside the allowed range")

    def validate_key(self, key: str) -> None:
        if (
            not key
            or key.startswith("/")
            or "\\" in key
            or "//" in key
            or any(segment in {"", ".", ".."} for segment in key.split("/"))
        ):
            raise StoragePolicyError("object key is not opaque and relative")
        if any(
            not character.isalnum() and character not in "._-/" for character in key
        ):
            raise StoragePolicyError("object key contains unsupported characters")


class ObjectStorage(Protocol):
    def put(self, key: str, body: bytes, content_type: str) -> ObjectMetadata: ...

    def head(self, key: str) -> ObjectMetadata: ...

    def get_object(self, key: str) -> tuple[bytes, ObjectMetadata]: ...

    def signed_get_url(
        self, key: str, expires_seconds: int = SIGNED_URL_SECONDS
    ) -> SignedObjectUrl: ...

    def delete(self, key: str) -> None: ...


def generate_object_key(owner_id: int, content_type: str) -> str:
    if owner_id < 1:
        raise StoragePolicyError("owner id must be positive")
    try:
        extension = EXTENSIONS[content_type]
    except KeyError as error:
        raise StoragePolicyError("content type is not allowed") from error
    return f"users/{owner_id}/{uuid4().hex}{extension}"


def _metadata(
    key: str, body: bytes, content_type: str, etag: str | None = None
) -> ObjectMetadata:
    return ObjectMetadata(
        key=key,
        content_type=content_type,
        size_bytes=len(body),
        checksum_sha256=hashlib.sha256(body).hexdigest(),
        etag=etag,
    )


def _signed(url: str, key: str, expires_seconds: int) -> SignedObjectUrl:
    if expires_seconds != SIGNED_URL_SECONDS:
        raise StoragePolicyError("signed URLs must expire after exactly 300 seconds")
    return SignedObjectUrl(
        url=url,
        key=key,
        expires_seconds=expires_seconds,
        expires_at=datetime.now(timezone.utc) + timedelta(seconds=expires_seconds),
    )


class MemoryObjectStorage:
    """Real-behavior in-memory adapter for unit tests."""

    def __init__(self, policy: StoragePolicy):
        self.policy = policy
        self._objects: dict[str, tuple[bytes, ObjectMetadata]] = {}

    def put(self, key: str, body: bytes, content_type: str) -> ObjectMetadata:
        self.policy.validate_key(key)
        self.policy.validate(content_type, len(body))
        metadata = _metadata(key, body, content_type)
        self._objects[key] = (bytes(body), metadata)
        return metadata

    def head(self, key: str) -> ObjectMetadata:
        self.policy.validate_key(key)
        try:
            return self._objects[key][1]
        except KeyError as error:
            raise ObjectNotFound("private object not found") from error

    def get_object(self, key: str) -> tuple[bytes, ObjectMetadata]:
        self.policy.validate_key(key)
        try:
            body, metadata = self._objects[key]
        except KeyError as error:
            raise ObjectNotFound("private object not found") from error
        return bytes(body), metadata

    def signed_get_url(
        self, key: str, expires_seconds: int = SIGNED_URL_SECONDS
    ) -> SignedObjectUrl:
        self.head(key)
        return _signed(f"memory://{quote(key)}", key, expires_seconds)

    def delete(self, key: str) -> None:
        self.policy.validate_key(key)
        if self._objects.pop(key, None) is None:
            raise ObjectNotFound("private object not found")


class LocalObjectStorage:
    """Non-public development adapter; no application route serves this directory."""

    def __init__(self, root: Path, policy: StoragePolicy):
        self.root = root.resolve()
        self.policy = policy

    def _path(self, key: str) -> Path:
        self.policy.validate_key(key)
        candidate = (self.root / key).resolve()
        if self.root not in candidate.parents:
            raise StoragePolicyError("object key escapes storage root")
        return candidate

    def put(self, key: str, body: bytes, content_type: str) -> ObjectMetadata:
        self.policy.validate(content_type, len(body))
        path = self._path(key)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(body)
        return _metadata(key, body, content_type)

    def head(self, key: str) -> ObjectMetadata:
        return self.get_object(key)[1]

    def get_object(self, key: str) -> tuple[bytes, ObjectMetadata]:
        path = self._path(key)
        if not path.is_file():
            raise ObjectNotFound("private object not found")
        body = path.read_bytes()
        content_type = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
        return body, _metadata(key, body, content_type)

    def signed_get_url(
        self, key: str, expires_seconds: int = SIGNED_URL_SECONDS
    ) -> SignedObjectUrl:
        self.head(key)
        return _signed(f"local-object://{quote(key)}", key, expires_seconds)

    def delete(self, key: str) -> None:
        path = self._path(key)
        try:
            path.unlink()
        except FileNotFoundError as error:
            raise ObjectNotFound("private object not found") from error


class S3ObjectStorage:
    def __init__(
        self,
        client,
        bucket: str,
        policy: StoragePolicy,
    ):
        self.client = client
        self.bucket = bucket
        self.policy = policy

    def _translate(self, error: Exception) -> StorageError:
        if isinstance(error, ClientError):
            code = error.response.get("Error", {}).get("Code", "")
            if code in {"404", "NoSuchKey", "NotFound"}:
                return ObjectNotFound("private object not found")
        return StorageUnavailable("private object storage is unavailable")

    def put(self, key: str, body: bytes, content_type: str) -> ObjectMetadata:
        self.policy.validate_key(key)
        self.policy.validate(content_type, len(body))
        metadata = _metadata(key, body, content_type)
        try:
            response = self.client.put_object(
                Bucket=self.bucket,
                Key=key,
                Body=body,
                ContentType=content_type,
                Metadata={"sha256": metadata.checksum_sha256},
            )
        except (BotoCoreError, ClientError) as error:
            raise self._translate(error) from error
        return ObjectMetadata(
            **{**metadata.__dict__, "etag": response.get("ETag", "").strip('"') or None}
        )

    def head(self, key: str) -> ObjectMetadata:
        self.policy.validate_key(key)
        try:
            response = self.client.head_object(Bucket=self.bucket, Key=key)
        except (BotoCoreError, ClientError) as error:
            raise self._translate(error) from error
        return ObjectMetadata(
            key=key,
            content_type=response.get("ContentType", "application/octet-stream"),
            size_bytes=int(response["ContentLength"]),
            checksum_sha256=response.get("Metadata", {}).get("sha256", ""),
            etag=response.get("ETag", "").strip('"') or None,
        )

    def get_object(self, key: str) -> tuple[bytes, ObjectMetadata]:
        self.policy.validate_key(key)
        try:
            response = self.client.get_object(Bucket=self.bucket, Key=key)
            body = response["Body"].read()
        except (BotoCoreError, ClientError) as error:
            raise self._translate(error) from error
        return body, ObjectMetadata(
            key=key,
            content_type=response.get("ContentType", "application/octet-stream"),
            size_bytes=len(body),
            checksum_sha256=response.get("Metadata", {}).get("sha256", ""),
            etag=response.get("ETag", "").strip('"') or None,
        )

    def signed_get_url(
        self, key: str, expires_seconds: int = SIGNED_URL_SECONDS
    ) -> SignedObjectUrl:
        self.policy.validate_key(key)
        if expires_seconds != SIGNED_URL_SECONDS:
            raise StoragePolicyError(
                "signed URLs must expire after exactly 300 seconds"
            )
        try:
            url = self.client.generate_presigned_url(
                "get_object",
                Params={"Bucket": self.bucket, "Key": key},
                ExpiresIn=expires_seconds,
            )
        except (BotoCoreError, ClientError) as error:
            raise self._translate(error) from error
        return _signed(url, key, expires_seconds)

    def delete(self, key: str) -> None:
        self.policy.validate_key(key)
        try:
            self.client.delete_object(Bucket=self.bucket, Key=key)
        except (BotoCoreError, ClientError) as error:
            raise self._translate(error) from error


def create_object_storage(settings: Settings) -> ObjectStorage:
    policy = StoragePolicy(max_bytes=settings.storage_max_bytes)
    if settings.storage_backend == "memory":
        return MemoryObjectStorage(policy)
    if settings.storage_backend == "local":
        return LocalObjectStorage(settings.storage_local_directory, policy)

    if (
        settings.storage_endpoint_url is None
        or settings.storage_access_key is None
        or settings.storage_secret_key is None
    ):
        raise StoragePolicyError("S3 storage configuration is incomplete")

    client = boto3.client(
        "s3",
        endpoint_url=str(settings.storage_endpoint_url).rstrip("/"),
        region_name=settings.storage_region,
        aws_access_key_id=settings.storage_access_key,
        aws_secret_access_key=settings.storage_secret_key.get_secret_value(),
        config=Config(signature_version="s3v4", s3={"addressing_style": "path"}),
    )
    return S3ObjectStorage(client, settings.storage_bucket, policy)


_storage: ObjectStorage | None = None


def get_storage() -> ObjectStorage:
    """FastAPI dependency — process-wide storage adapter (overridable in tests)."""
    global _storage
    if _storage is None:
        from settings import get_settings

        _storage = create_object_storage(get_settings())
    return _storage
