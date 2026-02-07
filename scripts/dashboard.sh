#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

ensure_docker_running
load_env

URL="$(compose run --rm openclaw-cli dashboard --no-open | tr -d '\r' | tail -n 1 || true)"
if [[ -z "${URL:-}" ]]; then
  die "Could not obtain dashboard URL. Is the config mounted and OPENCLAW_GATEWAY_TOKEN set?"
fi

echo "$URL"

if is_macos; then
  if command -v open >/dev/null 2>&1; then
    echo ""
    read -r -p "Open in browser now? [y/N]: " yn || true
    if [[ "${yn:-}" == "y" || "${yn:-}" == "Y" ]]; then
      open "$URL" || true
    fi
  fi
fi
