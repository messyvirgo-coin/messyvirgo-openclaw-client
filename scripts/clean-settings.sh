#!/usr/bin/env bash
set -euo pipefail

# Remove all OpenClaw config/state and generate a fresh token. Next: re-run setup/onboard.
# Usage: ./scripts/clean-settings.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

ensure_docker_running
load_env

CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw-secure}"
SRC_DIR="${OPENCLAW_SRC_DIR:-$CONFIG_DIR/openclaw-src}"

# ---- Stop containers ----
info "Stopping OpenClaw containers"
compose_base down --remove-orphans 2>/dev/null || true

# ---- Backup then remove config (keep openclaw-src for faster rebuild) ----
if [[ -d "$CONFIG_DIR" ]]; then
  BACKUP="${CONFIG_DIR}.backup.$(date +%Y%m%d-%H%M%S)"
  info "Backing up config to $BACKUP"
  mv "$CONFIG_DIR" "$BACKUP"
  mkdir -p "$CONFIG_DIR"
  # Restore only openclaw-src so we don't re-clone on next setup
  if [[ -d "$BACKUP/openclaw-src" ]]; then
    mv "$BACKUP/openclaw-src" "$CONFIG_DIR/"
    info "Kept openclaw-src for faster rebuild"
  fi
else
  mkdir -p "$CONFIG_DIR"
fi

# ---- New token in .env ----
if [[ -f "$ENV_FILE" ]]; then
  NEW_TOKEN=""
  if command -v openssl >/dev/null 2>&1; then
    NEW_TOKEN="$(openssl rand -hex 32)"
  else
    NEW_TOKEN="$(python3 -c 'import secrets; print(secrets.token_hex(32))')"
  fi
  # Replace OPENCLAW_GATEWAY_TOKEN in .env
  if grep -q '^OPENCLAW_GATEWAY_TOKEN=' "$ENV_FILE"; then
    sed -i.bak "s/^OPENCLAW_GATEWAY_TOKEN=.*/OPENCLAW_GATEWAY_TOKEN=$NEW_TOKEN/" "$ENV_FILE"
  else
    echo "OPENCLAW_GATEWAY_TOKEN=$NEW_TOKEN" >> "$ENV_FILE"
  fi
  rm -f "$ENV_FILE.bak"
  info "Generated new gateway token in .env"
fi

info "Done. Old settings removed and config backed up."
info "Next: run ./scripts/clean-and-start.sh to re-onboard and start the gateway."
