"""Unit tests for auth helpers — no DB required."""

import os
import sys

import pytest
from jose import JWTError

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

from auth import (
    create_access_token,
    decode_access_token,
    hash_password,
    verify_password,
)


def test_hash_and_verify_roundtrip():
    h = hash_password("secret123")
    assert verify_password("secret123", h)


def test_wrong_password_rejected():
    h = hash_password("correct")
    assert not verify_password("wrong", h)


def test_token_roundtrip():
    token = create_access_token(user_id=42)
    payload = decode_access_token(token)
    assert payload["sub"] == "42"


def test_tampered_token_raises():
    token = create_access_token(user_id=1)
    bad = token[:-4] + "XXXX"
    with pytest.raises(JWTError):
        decode_access_token(bad)


def test_unique_hashes():
    # bcrypt uses random salt — same password produces different hashes
    h1 = hash_password("same")
    h2 = hash_password("same")
    assert h1 != h2
    assert verify_password("same", h1)
    assert verify_password("same", h2)
