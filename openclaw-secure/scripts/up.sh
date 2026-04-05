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
# Use compose() (not compose_base) so Linux matches setup.sh: docker-compose.linux-hostnet.yml
# when present. up.sh previously used bridge + published ports on Linux whenever bind succeeded,
# which diverged from setup and produced NetworkMode=openclaw-secure_default.
set +e
OUT="$(compose up -d openclaw-gateway 2>&1)"
CODE=$?
set -e
if [[ $CODE -ne 0 ]]; then
  echo "$OUT" >&2
  exit "$CODE"
fi

info "Dashboard (localhost-only): http://127.0.0.1:${OPENCLAW_GATEWAY_PORT:-18789}/"
info "Gateway auth token is required; run ./openclaw-secure/scripts/dashboard.sh for the tokenized URL."
