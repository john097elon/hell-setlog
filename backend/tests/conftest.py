"""Shared pytest fixtures — in-memory SQLite, TestClient, user helpers."""
import os
import sys

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

# Make backend package importable from any working directory
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database import Base, get_db
from main import app


@pytest.fixture(scope="function")
def db_engine():
    engine = create_engine(
        "sqlite://",  # pure in-memory; StaticPool shares the same connection
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    import models  # noqa: F401 — registers all ORM models with Base.metadata
    Base.metadata.create_all(bind=engine)
    yield engine
    Base.metadata.drop_all(bind=engine)
    engine.dispose()


@pytest.fixture(scope="function")
def db(db_engine):
    Session = sessionmaker(autocommit=False, autoflush=False, bind=db_engine)
    session = Session()
    yield session
    session.close()


@pytest.fixture(scope="function")
def client(db):
    """TestClient with get_db overridden to use the in-memory session."""
    def _override_get_db():
        yield db

    app.dependency_overrides[get_db] = _override_get_db
    # Do NOT use context manager — avoids running startup (init_db on prod engine)
    yield TestClient(app, raise_server_exceptions=True)
    app.dependency_overrides.clear()


# ── Helpers ────────────────────────────────────────────────────────────────


def register(client, username: str, password: str = "pass1234", suffix: str = "") -> dict:
    email = f"{username}{suffix}@test.com"
    r = client.post("/api/auth/register", json={
        "username": username,
        "email": email,
        "password": password,
    })
    assert r.status_code == 201, r.json()
    return r.json()


def login(client, username: str, password: str = "pass1234") -> str:
    r = client.post("/api/auth/login", json={"username": username, "password": password})
    assert r.status_code == 200, r.json()
    return r.json()["access_token"]


def auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def make_user(client, name: str, password: str = "pass1234", suffix: str = "") -> tuple[dict, str]:
    """Register + login; returns (user_json, token)."""
    user = register(client, name, password, suffix)
    token = login(client, name, password)
    return user, token
