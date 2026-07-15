#!/usr/bin/env python3
"""Run the core application flow against an isolated restored database."""

from __future__ import annotations

import json
import time

from fastapi.testclient import TestClient

from main import app


def require_status(response, expected: int, endpoint: str) -> None:
    if response.status_code != expected:
        print(
            json.dumps(
                {
                    "status": "failed",
                    "endpoint": endpoint,
                    "http_status": response.status_code,
                }
            )
        )
        raise SystemExit(1)


def main() -> int:
    username = f"restore_smoke_{int(time.time() * 1000)}"
    password = "restore-smoke-password"
    checks = []

    with TestClient(app) as client:
        for path in ("/healthz", "/readyz"):
            require_status(client.get(path), 200, path)
            checks.append(path)

        endpoint = "/api/auth/register"
        response = client.post(
            endpoint,
            json={
                "username": username,
                "email": f"{username}@example.com",
                "password": password,
            },
        )
        require_status(response, 201, endpoint)
        checks.append(endpoint)

        endpoint = "/api/auth/login"
        response = client.post(
            endpoint, json={"username": username, "password": password}
        )
        require_status(response, 200, endpoint)
        token = response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        checks.append(endpoint)

        endpoint = "/api/parties/"
        response = client.post(
            endpoint, json={"name": "Restore Smoke Party"}, headers=headers
        )
        require_status(response, 201, endpoint)
        party_id = response.json()["id"]
        checks.append(endpoint)

        endpoint = "/api/workouts/"
        response = client.post(
            endpoint,
            json={"party_id": party_id, "notes": "restore smoke"},
            headers=headers,
        )
        require_status(response, 201, endpoint)
        checks.append(endpoint)

    print(json.dumps({"status": "ok", "checks": checks}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
