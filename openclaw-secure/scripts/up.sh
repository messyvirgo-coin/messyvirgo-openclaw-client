#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

ensure_docker_running
load_env

CONFIG_DIR="$(openclaw_host_config_dir)"
if [[ -n "${OPENCLAW_WORKSPACES_DIR:-}" ]]; then
  WORKSPACES_DIR="$OPENCLAW_WORKSPACES_DIR"
elif [[ -n "${OPENCLAW_WORKSPACE_DIR:-}" ]]; then
  WORKSPACES_DIR="$(dirname "$OPENCLAW_WORKSPACE_DIR")"
else
  WORKSPACES_DIR="$CONFIG_DIR/workspaces"
fi
WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$WORKSPACES_DIR/main}"

ensure_host_dir_writable "$CONFIG_DIR" "config/state directory"
chmod 700 "$CONFIG_DIR"
ensure_host_dir_writable "$WORKSPACES_DIR" "workspaces root directory"
ensure_host_dir_writable "$WORKSPACE_DIR" "default workspace directory"

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
info "Tokenized Control UI (prints URL): ${OPENCLAW_SECURE_ROOT}/scripts/dashboard.sh"
