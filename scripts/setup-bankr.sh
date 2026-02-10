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

if [[ -n "${BANKR_API_KEY:-}" ]]; then
  if [[ ! -f "$CONFIG_JSON" ]]; then
    cp "$EXAMPLE" "$CONFIG_JSON"
    info "Created $CONFIG_JSON from example."
  fi
  if command -v jq &>/dev/null; then
    jq --arg k "$BANKR_API_KEY" '.apiKey = $k' "$CONFIG_JSON" > "$CONFIG_JSON.tmp" && mv "$CONFIG_JSON.tmp" "$CONFIG_JSON"
    info "Updated apiKey in $CONFIG_JSON from BANKR_API_KEY."
  else
    info "BANKR_API_KEY is set but jq is not installed. Edit $CONFIG_JSON and set apiKey manually."
  fi
elif [[ -f "$CONFIG_JSON" ]]; then
  info "Config already exists: $CONFIG_JSON (not overwriting). Set BANKR_API_KEY in .env.api-keys to update from env."
else
  cp "$EXAMPLE" "$CONFIG_JSON"
  info "Created $CONFIG_JSON from example."
  info "Set BANKR_API_KEY in .env.api-keys and run this script again, or edit $CONFIG_JSON and add your Bankr API key, then restart the gateway: ./scripts/up.sh"
fi
