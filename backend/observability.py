"""Operational health, correlation, logging, metrics, and error tracking."""

from __future__ import annotations

import re
import time
from typing import Any
from uuid import uuid4

import sentry_sdk
import structlog
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
from sqlalchemy import text
from sqlalchemy.engine import Engine
from sqlalchemy.exc import SQLAlchemyError
from starlette.middleware.base import BaseHTTPMiddleware

from settings import Settings

REQUEST_ID_PATTERN = re.compile(r"^[A-Za-z0-9._-]{8,128}$")
SENSITIVE_KEYS = frozenset(
    {
        "authorization",
        "cookie",
        "email",
        "body",
        "filename",
        "signed_url",
        "password",
        "token",
        "secret",
    }
)

HTTP_REQUESTS = Counter(
    "hellsetlog_http_requests_total",
    "HTTP requests completed by the application.",
    ("method", "route", "status"),
)
HTTP_LATENCY = Histogram(
    "hellsetlog_http_request_duration_seconds",
    "HTTP request latency by route template.",
    ("method", "route"),
)
READINESS_FAILURES = Counter(
    "hellsetlog_readiness_failures_total",
    "Database readiness checks that failed.",
)


def _sanitize(value: Any) -> Any:
    if isinstance(value, dict):
        return {
            key: _sanitize(item)
            for key, item in value.items()
            if str(key).lower() not in SENSITIVE_KEYS
        }
    if isinstance(value, list):
        return [_sanitize(item) for item in value]
    if isinstance(value, tuple):
        return tuple(_sanitize(item) for item in value)
    return value


def redact_sensitive(_logger, _method_name, event_dict: dict[str, Any]) -> dict[str, Any]:
    """Drop known sensitive fields recursively before rendering a log event."""

    return _sanitize(event_dict)


def _sentry_before_send(event: dict[str, Any], _hint):
    event.pop("request", None)
    user = event.get("user")
    if isinstance(user, dict):
        for key in ("email", "ip_address", "username"):
            user.pop(key, None)
    return _sanitize(event)


def _configure_logging(settings: Settings) -> None:
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.processors.TimeStamper(fmt="iso", utc=True),
            structlog.processors.add_log_level,
            redact_sensitive,
            structlog.processors.JSONRenderer(sort_keys=True),
        ],
        logger_factory=structlog.PrintLoggerFactory(),
        cache_logger_on_first_use=True,
    )
    if settings.sentry_dsn:
        sentry_sdk.init(
            dsn=settings.sentry_dsn,
            environment=settings.app_env,
            release=settings.release,
            send_default_pii=False,
            max_request_body_size="never",
            before_send=_sentry_before_send,
        )


class RequestContextMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, settings: Settings):
        super().__init__(app)
        self.settings = settings
        self.logger = structlog.get_logger("hellsetlog.http")

    async def dispatch(self, request: Request, call_next):
        inbound = request.headers.get("X-Request-ID")
        request_id = (
            inbound
            if inbound is not None and REQUEST_ID_PATTERN.fullmatch(inbound)
            else str(uuid4())
        )
        started = time.perf_counter()
        status_code = 500
        route_template = "unmatched"
        structlog.contextvars.clear_contextvars()
        structlog.contextvars.bind_contextvars(request_id=request_id)
        try:
            response = await call_next(request)
            status_code = response.status_code
            route = request.scope.get("route")
            route_template = getattr(route, "path", "unmatched")
            response.headers["X-Request-ID"] = request_id
            return response
        except Exception as error:
            sentry_sdk.set_tag("request_id", request_id)
            sentry_sdk.capture_exception(error)
            raise
        finally:
            latency_seconds = time.perf_counter() - started
            HTTP_REQUESTS.labels(
                method=request.method,
                route=route_template,
                status=str(status_code),
            ).inc()
            HTTP_LATENCY.labels(
                method=request.method,
                route=route_template,
            ).observe(latency_seconds)
            self.logger.info(
                "http_request",
                service="hell-setlog",
                release=self.settings.release,
                environment=self.settings.app_env,
                request_id=request_id,
                method=request.method,
                route=route_template,
                status=status_code,
                latency_ms=round(latency_seconds * 1000, 2),
            )
            structlog.contextvars.clear_contextvars()


def configure_observability(
    app: FastAPI,
    settings: Settings,
    database_engine: Engine,
) -> None:
    """Attach operational middleware and dependency-safe endpoints."""

    _configure_logging(settings)
    app.add_middleware(RequestContextMiddleware, settings=settings)

    @app.get("/healthz", include_in_schema=False)
    def healthz():
        return {"status": "ok"}

    @app.get("/readyz", include_in_schema=False)
    def readyz():
        try:
            with database_engine.connect() as connection:
                connection.execute(text("SELECT 1")).scalar_one()
        except (SQLAlchemyError, OSError, TimeoutError):
            READINESS_FAILURES.inc()
            return JSONResponse(
                status_code=503,
                content={"status": "unavailable"},
            )
        return {"status": "ready"}

    @app.get("/metrics", include_in_schema=False)
    def metrics():
        return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)
