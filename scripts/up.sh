#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

ensure_docker_running
load_env

CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw-secure}"
if [[ -d "$CONFIG_DIR" ]]; then
  chmod 700 "$CONFIG_DIR"
fi

info "Starting OpenClaw gateway (secure compose overlay)"
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
    info "Dashboard (localhost-only): http://127.0.0.1:${OPENCLAW_GATEWAY_PORT:-18789}/"
    info "Gateway auth token is required; run ./scripts/dashboard.sh for the tokenized URL."
    exit 0
  fi
  exit "$CODE"
fi

info "Dashboard (localhost-only): http://127.0.0.1:${OPENCLAW_GATEWAY_PORT:-18789}/"
info "Gateway auth token is required; run ./scripts/dashboard.sh for the tokenized URL."
