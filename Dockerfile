FROM node:22-alpine AS frontend-build
WORKDIR /build/frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

FROM python:3.12-slim AS runtime
ARG POSTGRESQL_CLIENT_MAJOR=16
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app/backend:/app \
    FRONTEND_DIST=/app/frontend/dist
WORKDIR /app

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl \
    && install -d /usr/share/postgresql-common/pgdg \
    && curl --fail --show-error --silent \
      --output /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
      https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    && . /etc/os-release \
    && printf 'Types: deb\nURIs: https://apt.postgresql.org/pub/repos/apt\nSuites: %s-pgdg\nComponents: main\nSigned-By: /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc\n' \
      "$VERSION_CODENAME" > /etc/apt/sources.list.d/pgdg.sources \
    && apt-get update \
    && apt-get install --yes --no-install-recommends \
      "postgresql-client-${POSTGRESQL_CLIENT_MAJOR}" \
    && pg_restore --version | grep -Eq "PostgreSQL\) ${POSTGRESQL_CLIENT_MAJOR}\." \
    && apt-get purge --yes --auto-remove curl \
    && rm -rf /var/lib/apt/lists/* \
      /etc/apt/sources.list.d/pgdg.sources \
      /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
    && groupadd --gid 10001 hellsetlog \
    && useradd --uid 10001 --gid 10001 --no-create-home --shell /usr/sbin/nologin hellsetlog

COPY backend/requirements.txt /app/backend/requirements.txt
RUN python -m pip install --no-cache-dir --requirement /app/backend/requirements.txt

COPY backend/ /app/backend/
COPY ops/ /app/ops/
COPY --from=frontend-build /build/frontend/dist /app/frontend/dist

RUN sed -i 's/\r$//' /app/ops/*.sh \
    && chmod 0555 /app/ops/*.sh \
    && chown -R 10001:10001 /app

USER 10001:10001
EXPOSE 8000
ENTRYPOINT ["/app/ops/entrypoint.sh"]
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers", "--forwarded-allow-ips=*"]
