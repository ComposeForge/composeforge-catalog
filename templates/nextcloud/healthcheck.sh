#!/usr/bin/env bash
# Exits 1 if Nextcloud isn’t answering HTTP 200 on /status.php.
set -euo pipefail
source .env || true  # still succeeds if env not present
HOST="${HEALTHCHECK_HOST:-localhost}"
PORT="${HEALTHCHECK_PORT:-${NEXTCLOUD_PORT:-8080}}"

status=$(curl -fsSL -o /dev/null -w "%{http_code}" \
              --max-time 5 "http://$HOST:$PORT/status.php") || status="000"

if [[ "$status" != "200" ]]; then
  echo "Nextcloud healthcheck failed (HTTP $status)" >&2
  exit 1
fi

echo "Nextcloud healthy (HTTP 200)"
