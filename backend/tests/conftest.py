"""Shared test fixtures for Hell Setlog backend tests."""

import os
import sys

os.environ.setdefault("ENV", "dev")

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import auth as _auth_module
import database
import models  # noqa: F401 — registers all models with Base
from database import get_db

# Import app once at module level to avoid re-import issues
from main import app as _app


@pytest.fixture(autouse=True)
def _clear_rate_limits():
    """Reset in-memory rate limit buckets between tests when configured."""
    rate_buckets = getattr(_auth_module, "_rate_buckets", None)
    if rate_buckets is not None:
        rate_buckets.clear()
    yield
    if rate_buckets is not None:
        rate_buckets.clear()


@pytest.fixture()
def client():
    # StaticPool: all connections share the same in-memory DB so create_all
    # and test sessions see the same tables
    test_engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestSession = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)
    _app.state.test_session_factory = TestSession

    # Create all tables on the test engine directly
    database.Base.metadata.create_all(bind=test_engine)

    def override_get_db():
        db = TestSession()
        try:
            yield db
        finally:
            db.close()

    _app.dependency_overrides[get_db] = override_get_db

    # Use TestClient without triggering startup lifespan events
    c = TestClient(_app, raise_server_exceptions=True)
    yield c

    _app.dependency_overrides.clear()
    del _app.state.test_session_factory
    database.Base.metadata.drop_all(bind=test_engine)


@pytest.fixture()
def db(client):
    """A direct database session sharing the API test database."""
    session = client.app.state.test_session_factory()
    try:
        yield session
    finally:
        session.close()


def register_and_login(
    client: TestClient, username: str, password: str = "pass1234"
) -> str:
    """Register a user and return their access token."""
    client.post(
        "/api/auth/register",
        json={
            "username": username,
            "email": f"{username}@example.com",
            "password": password,
        },
    )
    resp = client.post(
        "/api/auth/login", json={"username": username, "password": password}
    )
    assert resp.status_code == 200, resp.text
    return resp.json()["access_token"]


def auth_headers(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def register(
    client, username: str, password: str = "pass1234", suffix: str = ""
) -> dict:
    email = f"{username}{suffix}@test.com"
    r = client.post(
        "/api/auth/register",
        json={
            "username": username,
            "email": email,
            "password": password,
        },
    )
    assert r.status_code == 201, r.json()
    return r.json()


def login(client, username: str, password: str = "pass1234") -> str:
    r = client.post(
        "/api/auth/login", json={"username": username, "password": password}
    )
    assert r.status_code == 200, r.json()
    return r.json()["access_token"]


def auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def make_user(
    client, name: str, password: str = "pass1234", suffix: str = ""
) -> tuple[dict, str]:
    """Register + login; returns (user_json, token)."""
    user = register(client, name, password, suffix)
    token = login(client, name, password)
    return user, token
