#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

ensure_docker_running
load_env

CONFIG_DIR="$(openclaw_host_config_dir)"
if [[ -d "$CONFIG_DIR" ]]; then
  chmod 700 "$CONFIG_DIR"
fi

info "Starting OpenClaw gateway"
# compose() selects the Linux hostnet overlay when present (consistent with setup.sh).
set +e
OUT="$(compose up -d openclaw-gateway 2>&1)"
CODE=$?
set -e
if [[ $CODE -ne 0 ]]; then
  echo "$OUT" >&2
  exit "$CODE"
fi

info "Dashboard: http://127.0.0.1:${OPENCLAW_GATEWAY_PORT:-18789}/"
info "Authenticated URL: ./openclaw-secure/scripts/dashboard.sh"
