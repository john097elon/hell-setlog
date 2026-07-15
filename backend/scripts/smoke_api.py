#!/usr/bin/env python3
"""Minimal HTTP smoke test for the Hell Setlog API.

Usage:
    python backend/scripts/smoke_api.py [BASE_URL]

The backend must already be running, e.g.:
    cd backend && uvicorn main:app --host 0.0.0.0 --port 8000
"""

from __future__ import annotations

import json
import sys
import time
import urllib.error
import urllib.request
from typing import Any

BASE_URL = (sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8000").rstrip("/")
USERNAME = f"smoke_{int(time.time())}"
PASSWORD = "smoke-password"
EMAIL = f"{USERNAME}@example.com"


def request(
    method: str,
    path: str,
    payload: dict[str, Any] | None = None,
    token: str | None = None,
) -> tuple[int, Any]:
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    headers = {"Accept": "application/json"}
    if payload is not None:
        headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(
        f"{BASE_URL}{path}", data=data, headers=headers, method=method
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = resp.read().decode("utf-8")
            return resp.status, json.loads(body) if body else None
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8")
        try:
            parsed: Any = json.loads(body) if body else None
        except json.JSONDecodeError:
            parsed = body
        raise RuntimeError(
            f"{method} {path} failed with HTTP {exc.code}: {parsed}"
        ) from exc


def expect(status: int, expected: int, label: str) -> None:
    if status != expected:
        raise RuntimeError(f"{label}: expected HTTP {expected}, got {status}")
    print(f"OK {label} -> HTTP {status}")


def main() -> None:
    status, health = request("GET", "/api/health")
    expect(status, 200, "health")

    status, user = request(
        "POST",
        "/api/auth/register",
        {
            "username": USERNAME,
            "email": EMAIL,
            "password": PASSWORD,
        },
    )
    expect(status, 201, "register")

    status, login = request(
        "POST", "/api/auth/login", {"username": USERNAME, "password": PASSWORD}
    )
    expect(status, 200, "login")
    token = login["access_token"]

    status, me = request("GET", "/api/auth/me", token=token)
    expect(status, 200, "me")

    status, party = request(
        "POST", "/api/parties/", {"name": "Smoke Party"}, token=token
    )
    expect(status, 201, "create party")

    status, workout = request(
        "POST",
        "/api/workouts/",
        {"party_id": party["id"], "notes": "smoke"},
        token=token,
    )
    expect(status, 201, "create workout")

    print(
        "Smoke API flow passed:",
        json.dumps(
            {
                "user_id": user["id"],
                "party_id": party["id"],
                "workout_id": workout["id"],
                "health": health,
                "me": me["username"],
            },
            ensure_ascii=False,
        ),
    )


if __name__ == "__main__":
    main()
