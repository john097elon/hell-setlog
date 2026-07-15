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

import database
import models  # noqa: F401 — registers all models with Base
import auth as _auth_module

# Import app once at module level to avoid re-import issues
from main import app as _app
from database import get_db


@pytest.fixture(autouse=True)
def _clear_rate_limits():
    """Reset in-memory rate limit buckets between tests."""
    _auth_module._rate_buckets.clear()
    yield
    _auth_module._rate_buckets.clear()


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
    database.Base.metadata.drop_all(bind=test_engine)


def register_and_login(client: TestClient, username: str, password: str = "pass1234") -> str:
    """Register a user and return their access token."""
    client.post("/api/auth/register", json={
        "username": username,
        "email": f"{username}@example.com",
        "password": password,
    })
    resp = client.post("/api/auth/login", json={"username": username, "password": password})
    assert resp.status_code == 200, resp.text
    return resp.json()["access_token"]


def auth_headers(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}
