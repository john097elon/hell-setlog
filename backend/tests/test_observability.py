import importlib
import importlib.util
from uuid import UUID

from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine

from settings import Settings


def observability_module():
    assert importlib.util.find_spec("observability") is not None, (
        "observability module must exist"
    )
    return importlib.import_module("observability")


def configured_client(database_url: str = "sqlite://") -> TestClient:
    observability = observability_module()
    settings = Settings(
        _env_file=None,
        app_env="test",
        database_url=database_url,
        storage_backend="memory",
        release="test-release",
    )
    app = FastAPI()
    engine = create_engine(database_url)
    observability.configure_observability(app, settings, engine)
    return TestClient(app)


def test_health_is_live_even_when_database_is_unavailable():
    client = configured_client("sqlite:///file:missing-health?mode=ro&uri=true")

    response = client.get("/healthz")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_readiness_reports_database_success_without_details():
    client = configured_client()

    response = client.get("/readyz")

    assert response.status_code == 200
    assert response.json() == {"status": "ready"}


def test_readiness_failure_is_detail_free():
    client = configured_client("sqlite:///file:missing-ready?mode=ro&uri=true")

    response = client.get("/readyz")

    assert response.status_code == 503
    assert response.json() == {"status": "unavailable"}
    assert "sqlite" not in response.text.lower()


def test_request_id_accepts_safe_value_and_replaces_invalid_value():
    client = configured_client()

    accepted = client.get("/healthz", headers={"X-Request-ID": "request-abc-123"})
    generated = client.get(
        "/healthz", headers={"X-Request-ID": "bad value with spaces"}
    )

    assert accepted.headers["X-Request-ID"] == "request-abc-123"
    UUID(generated.headers["X-Request-ID"])


def test_redaction_removes_sensitive_fields():
    observability = observability_module()
    event = observability.redact_sensitive(
        None,
        None,
        {
            "event": "http_request",
            "request_id": "request-abc-123",
            "authorization": "Bearer secret",
            "cookie": "session=secret",
            "email": "person@example.test",
            "body": "private note",
            "filename": "private.jpg",
            "signed_url": "https://objects.example/secret",
        },
    )

    assert event == {
        "event": "http_request",
        "request_id": "request-abc-123",
    }


def test_metrics_include_request_counter():
    client = configured_client()
    client.get("/healthz")

    response = client.get("/metrics")

    assert response.status_code == 200
    assert "hellsetlog_http_requests_total" in response.text


def test_main_application_wires_operational_endpoints():
    main = importlib.import_module("main")
    paths = {route.path for route in main.app.routes if hasattr(route, "path")}

    assert {"/healthz", "/readyz", "/metrics"} <= paths


def test_alert_rules_cover_readiness_errors_latency_and_backup():
    from pathlib import Path

    path = Path("ops/prometheus/alerts.yml")
    assert path.exists(), "Prometheus alert rules must exist"
    source = path.read_text(encoding="utf-8")

    assert "HellSetlogReadinessFailure" in source
    assert "HellSetlogHighErrorRatio" in source
    assert "HellSetlogHighP95Latency" in source
    assert "HellSetlogBackupMissing" in source
    assert "for: 2m" in source
    assert "for: 5m" in source
    assert "for: 10m" in source
    assert "93600" in source
