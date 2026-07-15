#!/bin/sh
set -eu

image=${1:?full immutable application image is required}
app_host=${2:?staging application host is required}
env_file=${3:-/etc/hellsetlog/staging.env}
digest_pattern='^ghcr\.io/[a-z0-9._/-]+@sha256:[0-9a-f]{64}$'

if ! printf '%s' "$image" | grep -Eq "$digest_pattern"; then
  echo "application image must be a full GHCR sha256 digest" >&2
  exit 2
fi
if ! printf '%s' "$app_host" | grep -Eq '^[A-Za-z0-9.-]+$'; then
  echo "application host is invalid" >&2
  exit 2
fi
case "$env_file" in
  /*) ;;
  *) echo "staging environment file must be an absolute path" >&2; exit 2 ;;
esac
if [ ! -r "$env_file" ]; then
  echo "staging environment file is not readable: $env_file" >&2
  exit 2
fi

state_dir=${DEPLOY_STATE_DIR:-.deploy-state}
state_file="$state_dir/.last_image"
mkdir -p "$state_dir"
previous_image=""
if [ -r "$state_file" ]; then
  previous_image=$(sed -n '1p' "$state_file")
fi


deploy_image() {
  candidate=$1
  APP_IMAGE="$candidate" APP_HOST="$app_host" STAGING_ENV_FILE="$env_file" \
    docker compose --env-file "$env_file" -f compose.staging.yml pull &&
  APP_IMAGE="$candidate" APP_HOST="$app_host" STAGING_ENV_FILE="$env_file" \
    docker compose --env-file "$env_file" -f compose.staging.yml up -d --wait &&
  curl --fail --silent --show-error --retry 8 --retry-delay 2 --retry-all-errors \
    "https://$app_host/readyz" >/dev/null &&
  APP_IMAGE="$candidate" APP_HOST="$app_host" STAGING_ENV_FILE="$env_file" \
    docker compose --env-file "$env_file" -f compose.staging.yml exec -T app \
      python /app/backend/scripts/smoke_api.py "https://$app_host"
}

if deploy_image "$image"; then
  temporary_state="$state_file.tmp"
  printf '%s\n' "$image" > "$temporary_state"
  mv "$temporary_state" "$state_file"
  echo "staging deployment verified: $image"
  exit 0
fi

echo "candidate failed readiness or core smoke; starting rollback" >&2
if [ -n "$previous_image" ] && [ "$previous_image" != "$image" ]; then
  if deploy_image "$previous_image"; then
    echo "rollback verified: $previous_image" >&2
  else
    echo "rollback failed: operator intervention required" >&2
  fi
else
  echo "no previous image digest is available for rollback" >&2
fi
exit 1
