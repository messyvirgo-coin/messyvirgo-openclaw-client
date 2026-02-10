#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

# Merge .env.api-keys into .env so API keys survive setup.sh overwrites (e.g. after OpenClaw updates)
[[ -f "$ROOT_DIR/scripts/merge-env-api-keys.sh" ]] && "$ROOT_DIR/scripts/merge-env-api-keys.sh"

# If BANKR_API_KEY is in .env, update Bankr config so the gateway has a valid key
[[ -f "$ROOT_DIR/scripts/setup-bankr.sh" ]] && "$ROOT_DIR/scripts/setup-bankr.sh" 2>/dev/null || true

ensure_docker_running
load_env

# Start gateway first so the OpenClaw Control UI is always available (required for configuring OpenClaw).
# Then start X Monitor; if it fails to build or run, gateway is already up.
info "Starting OpenClaw gateway (Control UI required for configuration)"
set +e
OUT="$(compose_base up -d openclaw-gateway 2>&1)"
CODE=$?
set -e
if [[ $CODE -ne 0 ]]; then
  echo "$OUT" >&2
  if ! is_macos && echo "$OUT" | grep -q "failed to bind host port" && [[ -f "$ROOT_DIR/docker-compose.linux-hostnet.yml" ]]; then
    echo "" >&2
    echo "It looks like Docker port publishing is failing on this Linux host." >&2
    echo "Falling back to Linux host networking workaround." >&2
    echo "" >&2
    OPENCLAW_GATEWAY_BIND=loopback compose_linux_hostnet up -d openclaw-gateway
    info "OpenClaw Control UI: http://127.0.0.1:${OPENCLAW_GATEWAY_PORT:-18789}/"
    info "Run ./scripts/dashboard.sh for tokenized Control UI URL."
    compose_base up -d dashboard-x 2>/dev/null || true
    info "X Monitor: http://127.0.0.1:${DASHBOARD_X_PORT:-18788}/"
    exit 0
  fi
  exit "$CODE"
fi

info "OpenClaw Control UI: http://127.0.0.1:${OPENCLAW_GATEWAY_PORT:-18789}/"
info "Run ./scripts/dashboard.sh for tokenized Control UI URL."
compose_base up -d dashboard-x 2>/dev/null || true
info "X Monitor (Messy Virgo): http://127.0.0.1:${DASHBOARD_X_PORT:-18788}/"
