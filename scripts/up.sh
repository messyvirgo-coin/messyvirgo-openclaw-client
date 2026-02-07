#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

ensure_docker_running
load_env

info "Starting OpenClaw gateway (secure compose overlay)"
compose up -d openclaw-gateway

info "Dashboard (localhost-only): http://127.0.0.1:${OPENCLAW_GATEWAY_PORT:-18789}/"
