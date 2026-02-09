#!/usr/bin/env bash
# Moltbook CLI: connectivity test and basic API calls using saved credentials.
# Credentials: MOLTBOOK_API_KEY env, or ~/.config/moltbook/credentials.json
# API base: https://www.moltbook.com (always use www)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BASE_URL="https://www.moltbook.com/api/v1"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

# Load API key: env > .env > credentials file
get_api_key() {
  if [[ -n "${MOLTBOOK_API_KEY:-}" ]]; then
    echo "$MOLTBOOK_API_KEY"
    return
  fi
  local creds="${HOME:-/tmp}/.config/moltbook/credentials.json"
  if [[ -f "$creds" ]]; then
    if command -v jq >/dev/null 2>&1; then
      jq -r '.api_key // empty' "$creds" 2>/dev/null || true
    else
      grep -o '"api_key"[[:space:]]*:[[:space:]]*"[^"]*"' "$creds" 2>/dev/null | sed 's/.*"\([^"]*\)"$/\1/' || true
    fi
  fi
}

# Load .env first so MOLTBOOK_API_KEY is available if set there
if [[ -f "$ROOT_DIR/.env" ]]; then
  # shellcheck disable=SC1090
  set -a && source "$ROOT_DIR/.env" 2>/dev/null && set +a || true
fi

api_key="$(get_api_key)"
[[ -z "$api_key" ]] && die "No Moltbook API key. Set MOLTBOOK_API_KEY in .env or create ~/.config/moltbook/credentials.json with api_key."

curl_api() {
  curl -sS -w "\n" -H "Authorization: Bearer $api_key" "$@"
}

cmd="${1:-test}"

case "$cmd" in
  test|connectivity|status)
    # Connectivity test: GET /agents/status
    out="$(curl_api "$BASE_URL/agents/status")"
    if echo "$out" | grep -q '"success":true'; then
      echo "Moltbook connectivity: OK"
      echo "$out" | head -5
      exit 0
    else
      echo "Moltbook connectivity: FAILED" >&2
      echo "$out" >&2
      exit 1
    fi
    ;;
  me)
    curl_api "$BASE_URL/agents/me"
    ;;
  feed)
    limit="${2:-10}"
    curl_api "$BASE_URL/feed?sort=new&limit=$limit"
    ;;
  posts)
    limit="${2:-10}"
    curl_api "$BASE_URL/posts?sort=new&limit=$limit"
    ;;
  -h|--help|help)
    echo "Usage: $0 [command]"
    echo "  test (default)  - Connectivity test (GET /agents/status)"
    echo "  status          - Same as test"
    echo "  me              - Get current agent profile"
    echo "  feed [limit]    - Get personalized feed (default 10)"
    echo "  posts [limit]   - Get latest posts (default 10)"
    echo "Credentials: MOLTBOOK_API_KEY or ~/.config/moltbook/credentials.json"
    exit 0
    ;;
  *)
    die "Unknown command: $cmd. Use: $0 help"
    ;;
esac
