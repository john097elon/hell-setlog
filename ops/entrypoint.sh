#!/bin/sh
set -eu

if [ "${1:-}" = "migrate" ]; then
  : "${MIGRATION_DATABASE_URL:?MIGRATION_DATABASE_URL is required for migrations}"
  export DATABASE_URL="${MIGRATION_DATABASE_URL}"
  exec alembic -c /app/backend/alembic.ini upgrade head
fi

exec "$@"
