#!/usr/bin/env bash
# healthcheck.sh – waits up to 90 s for /status.php → HTTP 200
set -euo pipefail
source .env 2>/dev/null || true

HOST="${HEALTHCHECK_HOST:-localhost}"
PORT="${HEALTHCHECK_PORT:-${NEXTCLOUD_PORT:-8081}}"
URL="http://$HOST:$PORT/status.php"

max_attempts=18   # 18×5 s = 90 s
sleep_between=5

echo "⏳ Waiting for Nextcloud at $URL …"
for ((i=1; i<=max_attempts; i++)); do
  code=$(curl -fsSL -o /dev/null -w "%{http_code}" --max-time 3 "$URL" || true)
  if [[ "$code" == "200" ]]; then
    echo "✅ Nextcloud healthy (HTTP 200)"
    exit 0
  fi
  printf "  attempt %2d/%d … not ready (HTTP %s)\n" "$i" "$max_attempts" "${code:-000}"
  sleep "$sleep_between"
done

echo "❌ Health-check timed out after $((max_attempts*sleep_between)) s" >&2
exit 1

