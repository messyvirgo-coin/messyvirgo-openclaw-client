#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

ensure_docker_running
load_env

ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

# Read token directly from .env so it's never empty (trim CR/spaces).
TOKEN=""
if [[ -f "$ENV_FILE" ]]; then
  TOKEN="$(grep -E '^OPENCLAW_GATEWAY_TOKEN=' "$ENV_FILE" | cut -d= -f2- | tr -d '\r\n \t\"' || true)"
fi
if [[ -z "${TOKEN}" ]]; then
  die "OPENCLAW_GATEWAY_TOKEN is not set in .env. Run ./scripts/setup.sh or add the token to .env."
fi

PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
XPORT="${DASHBOARD_X_PORT:-18788}"
URL="http://127.0.0.1:${PORT}/?token=${TOKEN}"
XURL="http://127.0.0.1:${XPORT}/"

echo "$URL"
echo ""
info "X Monitor (Messy Virgo accounts): $XURL"
echo ""
info "If you see 'gateway token mismatch':"
info "  1. Restart the gateway so it uses the token from .env: ./scripts/down.sh && ./scripts/up.sh"
info "  2. In the dashboard, open Control UI → Settings and paste this token (replace any existing value):"
echo "     ${TOKEN}"
echo ""
info "Then open the URL above in your browser (or answer y to open it now)."

if is_macos; then
  if command -v open >/dev/null 2>&1; then
    echo ""
    read -r -p "Open in browser now? [y/N]: " yn || true
    if [[ "${yn:-}" == "y" || "${yn:-}" == "Y" ]]; then
      open "$URL" || true
    fi
  fi
fi
