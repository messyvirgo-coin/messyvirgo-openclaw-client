#!/usr/bin/env bash
set -euo pipefail

# Run OpenClaw CLI (native, no Docker).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

load_env

OPENCLAW_WORKSPACES_DIR="${OPENCLAW_WORKSPACES_DIR:-$HOME/.openclaw/workspaces}"
OPENCLAW_CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
OPENCLAW_CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$OPENCLAW_CONFIG_DIR/openclaw.json}"

export OPENCLAW_WORKSPACES_DIR
export OPENCLAW_CONFIG_PATH
export OPENCLAW_STATE_DIR="${OPENCLAW_STATE_DIR:-$OPENCLAW_CONFIG_DIR}"

require_cmd openclaw

exec openclaw "$@"
