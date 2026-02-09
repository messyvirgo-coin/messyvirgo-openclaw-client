#!/usr/bin/env bash
# One-time setup for the bankr skill: creates ~/.clawdbot/skills/bankr/config.json
# from the example so the container can read it. Edit config.json and add your API key.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

load_env

CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw-secure}"
CLAWDBOT_DIR="$CONFIG_DIR/clawdbot"
BANKR_DIR="$CLAWDBOT_DIR/skills/bankr"
CONFIG_JSON="$BANKR_DIR/config.json"
EXAMPLE="$SCRIPT_DIR/../config/clawdbot/skills/bankr/config.json.example"

if [[ ! -f "$EXAMPLE" ]]; then
  die "Example config not found: $EXAMPLE"
fi

mkdir -p "$BANKR_DIR"

if [[ -f "$CONFIG_JSON" ]]; then
  info "Config already exists: $CONFIG_JSON (not overwriting)"
else
  cp "$EXAMPLE" "$CONFIG_JSON"
  info "Created $CONFIG_JSON from example."
  info "Edit it and set your bankr API key, then restart the gateway: ./scripts/up.sh"
fi
