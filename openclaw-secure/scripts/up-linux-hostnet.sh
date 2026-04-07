#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

ensure_docker_running
load_env

if is_macos; then
  die "Host networking mode is Linux-only. Use ${OPENCLAW_SECURE_ROOT}/scripts/up.sh on macOS."
fi

info "Starting OpenClaw gateway (Linux host networking workaround)"
info "compose_linux_hostnet() forces OPENCLAW_GATEWAY_BIND=loopback (localhost-only)."

compose up -d openclaw-gateway

info "Dashboard (localhost-only): http://127.0.0.1:${OPENCLAW_GATEWAY_PORT:-18789}/"
info "Tokenized Control UI (prints URL): ${OPENCLAW_SECURE_ROOT}/scripts/dashboard.sh"
