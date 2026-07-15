#!/bin/sh
set -u

interval="${BACKUP_INTERVAL_SECONDS:-3600}"
case "$interval" in
  ''|*[!0-9]*)
    echo '{"error_type":"InvalidBackupInterval","status":"failed"}'
    exit 1
    ;;
esac

while true; do
  python -m ops.backup || true
  sleep "$interval"
done
