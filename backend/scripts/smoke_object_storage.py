#!/usr/bin/env python3
"""Verify private S3 behavior and exact signed-URL access."""

from __future__ import annotations

import json
import urllib.error
import urllib.request
from urllib.parse import quote

from settings import Settings
from storage import (
    ObjectNotFound,
    S3ObjectStorage,
    create_object_storage,
    generate_object_key,
)


def require_anonymous_denial(url: str) -> None:
    try:
        with urllib.request.urlopen(url, timeout=10):
            pass
    except urllib.error.HTTPError as error:
        if error.code in {401, 403}:
            return
        raise RuntimeError("anonymous storage request returned an unexpected status") from error
    raise RuntimeError("private object storage allowed anonymous access")


def main() -> int:
    settings = Settings()
    backend = create_object_storage(settings)
    if not isinstance(backend, S3ObjectStorage) or settings.storage_endpoint_url is None:
        raise RuntimeError("object storage smoke requires the S3 adapter")

    body = b"private-object-smoke"
    key = generate_object_key(owner_id=1, content_type="image/png")
    endpoint = str(settings.storage_endpoint_url).rstrip("/")
    object_url = f"{endpoint}/{quote(settings.storage_bucket)}/{quote(key, safe='/')}"
    list_url = f"{endpoint}/{quote(settings.storage_bucket)}?list-type=2"
    uploaded = False

    try:
        metadata = backend.put(key, body, "image/png")
        uploaded = True
        if metadata.size_bytes != len(body):
            raise RuntimeError("uploaded object metadata is inconsistent")

        require_anonymous_denial(object_url)
        require_anonymous_denial(list_url)

        signed = backend.signed_get_url(key)
        if signed.expires_seconds != 300:
            raise RuntimeError("signed URL expiry is not exactly 300 seconds")
        with urllib.request.urlopen(signed.url, timeout=10) as response:
            if response.read() != body:
                raise RuntimeError("signed object response is inconsistent")

        backend.delete(key)
        uploaded = False
        try:
            backend.head(key)
        except ObjectNotFound:
            pass
        else:
            raise RuntimeError("deleted object still exists")
    finally:
        if uploaded:
            backend.delete(key)

    print(json.dumps({"status": "ok", "checks": ["private-read", "private-list", "signed-get", "delete"]}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
