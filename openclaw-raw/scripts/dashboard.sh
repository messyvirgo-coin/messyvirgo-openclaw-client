#!/usr/bin/env bash
set -euo pipefail

# Print tokenized dashboard URL for native OpenClaw gateway.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

load_env

ENV_FILE="$REPO_ROOT/.env"

# Read token directly from .env so it's never empty (trim CR/spaces).
TOKEN=""
if [[ -f "$ENV_FILE" ]]; then
  TOKEN="$(grep -E '^OPENCLAW_GATEWAY_TOKEN=' "$ENV_FILE" | cut -d= -f2- | tr -d '\r\n \t\"' || true)"
fi
if [[ -z "${TOKEN}" ]]; then
  die "OPENCLAW_GATEWAY_TOKEN is not set in .env. Run ./openclaw-raw/scripts/setup.sh or add the token to .env."
fi

PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
URL="http://127.0.0.1:${PORT}/#token=${TOKEN}"

printf '%s\n' "$URL"

if is_macos; then
  if command -v open >/dev/null 2>&1; then
    echo ""
    read -r -p "Open in browser now? [y/N]: " yn || true
    if [[ "${yn:-}" == "y" || "${yn:-}" == "Y" ]]; then
      open "$URL" || true
    fi
  fi
fi
