import importlib
import importlib.util
import shutil
from pathlib import Path
from uuid import uuid4

from fastapi import FastAPI
from fastapi.testclient import TestClient


def frontend_module():
    assert importlib.util.find_spec("static_frontend") is not None, "static frontend module must exist"
    return importlib.import_module("static_frontend")


def test_spa_fallback_preserves_api_and_rejects_missing_asset():
    root = Path("backend/data") / f"frontend-test-{uuid4().hex}"
    root.mkdir(parents=True)
    (root / "index.html").write_text("<html>shell</html>", encoding="utf-8")
    (root / "asset.js").write_text("console.log('asset')", encoding="utf-8")
    try:
        app = FastAPI()

        @app.get("/api/ping")
        def ping():
            return {"status": "ok"}

        frontend_module().mount_frontend(app, root)
        client = TestClient(app)

        assert client.get("/api/ping").json() == {"status": "ok"}
        assert client.get("/dashboard").text == "<html>shell</html>"
        assert client.get("/asset.js").text == "console.log('asset')"
        assert client.get("/missing.js").status_code == 404
    finally:
        shutil.rmtree(root, ignore_errors=True)


def test_container_and_compose_contracts_are_reproducible():
    dockerfile = Path("Dockerfile")
    local_compose = Path("docker-compose.yml")
    staging_compose = Path("compose.staging.yml")
    entrypoint = Path("ops/entrypoint.sh")
    caddyfile = Path("ops/Caddyfile")

    for path in (dockerfile, local_compose, staging_compose, entrypoint, caddyfile):
        assert path.exists(), f"{path} must exist"

    docker_source = dockerfile.read_text(encoding="utf-8")
    assert "npm ci" in docker_source
    assert "USER 10001:10001" in docker_source
    assert "python:3.12-slim" in docker_source
    assert "node:22-alpine" in docker_source

    local_source = local_compose.read_text(encoding="utf-8")
    assert "postgres:16" in local_source
    assert "object-storage:" in local_source
    assert "migrate:" in local_source
    assert "service_completed_successfully" in local_source

    staging_source = staging_compose.read_text(encoding="utf-8")
    assert "APP_IMAGE" in staging_source
    assert "build:" not in staging_source
    assert "edge:" in staging_source

    entrypoint_source = entrypoint.read_text(encoding="utf-8")
    assert "alembic" in entrypoint_source
    assert "MIGRATION_DATABASE_URL" in entrypoint_source

    caddy_source = caddyfile.read_text(encoding="utf-8")
    assert "reverse_proxy app:8000" in caddy_source
    assert "/metrics" in caddy_source


def test_vite_no_longer_proxies_public_uploads():
    source = Path("frontend/vite.config.ts").read_text(encoding="utf-8")

    assert "'/uploads'" not in source
