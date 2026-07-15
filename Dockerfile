FROM node:22-alpine AS frontend-build
WORKDIR /build/frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

FROM python:3.12-slim AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app/backend:/app \
    FRONTEND_DIST=/app/frontend/dist
WORKDIR /app

RUN apt-get update \
    && apt-get install --yes --no-install-recommends postgresql-client ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 hellsetlog \
    && useradd --uid 10001 --gid 10001 --no-create-home --shell /usr/sbin/nologin hellsetlog

COPY backend/requirements.txt /app/backend/requirements.txt
RUN python -m pip install --no-cache-dir --requirement /app/backend/requirements.txt

COPY backend/ /app/backend/
COPY ops/ /app/ops/
COPY --from=frontend-build /build/frontend/dist /app/frontend/dist

RUN chmod 0555 /app/ops/*.sh \
    && chown -R 10001:10001 /app

USER 10001:10001
EXPOSE 8000
ENTRYPOINT ["/app/ops/entrypoint.sh"]
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers", "--forwarded-allow-ips=*"]
