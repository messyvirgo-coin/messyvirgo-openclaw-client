#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

ensure_docker_running
load_env

if is_macos; then
  die "Host networking mode is Linux-only. Use ./secure-client/scripts/up.sh on macOS."
fi

info "Starting OpenClaw gateway (Linux host networking workaround)"
info "For safety, forcing OPENCLAW_GATEWAY_BIND=loopback (localhost-only)."

# shellcheck disable=SC2068
OPENCLAW_GATEWAY_BIND=loopback \
docker compose \
  -f "$SECURE_CLIENT_ROOT/docker-compose.yml" \
  -f "$SECURE_CLIENT_ROOT/docker-compose.secure.yml" \
  -f "$SECURE_CLIENT_ROOT/docker-compose.linux-hostnet.yml" \
  -f "$SECURE_CLIENT_ROOT/docker-compose.skills.yml" \
  up -d openclaw-gateway

info "Dashboard (localhost-only): http://127.0.0.1:${OPENCLAW_GATEWAY_PORT:-18789}/"
