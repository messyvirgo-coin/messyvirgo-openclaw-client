#!/usr/bin/env bash
set -euo pipefail

# Bootstrap native (non-Docker) OpenClaw with this repo's config.
# Prerequisite: OpenClaw installed (npm i -g openclaw or equivalent).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

require_cmd openclaw
require_cmd npm

ENV_FILE="$REPO_ROOT/.env"
CONFIG_SRC="$REPO_ROOT/config/openclaw.json"

# Ensure .env exists
if [[ ! -f "$ENV_FILE" ]]; then
  if [[ -f "$REPO_ROOT/.env.raw.example" ]]; then
    cp "$REPO_ROOT/.env.raw.example" "$ENV_FILE"
    info "Created $ENV_FILE from .env.raw.example"
  else
    die "Missing .env.raw.example. Create .env with OPENCLAW_WORKSPACES_DIR, API keys, and OPENCLAW_GATEWAY_TOKEN."
  fi
fi

load_env

info "Installing @messyvirgo/cli globally (mv on PATH)"
npm install -g @messyvirgo/cli@latest

# Required for native config
if [[ -z "${OPENCLAW_WORKSPACES_DIR:-}" ]]; then
  OPENCLAW_WORKSPACES_DIR="${HOME:-}/.openclaw/workspaces"
  info "Using default OPENCLAW_WORKSPACES_DIR=$OPENCLAW_WORKSPACES_DIR (add to .env to override)"
fi
if [[ -z "${OPENCLAW_CONFIG_DIR:-}" ]]; then
  OPENCLAW_CONFIG_DIR="${HOME:-}/.openclaw"
  info "Using default OPENCLAW_CONFIG_DIR=$OPENCLAW_CONFIG_DIR (add to .env to override)"
fi

mkdir -p "$OPENCLAW_CONFIG_DIR"
mkdir -p "$OPENCLAW_WORKSPACES_DIR"

# Deploy shared template, then apply native-host overrides (bind/sandbox).
dest="$OPENCLAW_CONFIG_DIR/openclaw.json"
if [[ ! -f "$dest" ]]; then
  cp "$CONFIG_SRC" "$dest"
  patch_openclaw_config_for_native "$dest"
  info "Wrote $dest (from config/openclaw.json + native patch)"
else
  info "$dest already exists (leaving untouched). To refresh: ./openclaw-raw/scripts/upgrade.sh --sync-config"
fi

# Deploy workspace templates
deploy_workspace_templates "$REPO_ROOT" "$OPENCLAW_WORKSPACES_DIR" 0 0

# Generate token if missing
if [[ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]]; then
  if command -v openssl >/dev/null 2>&1; then
    OPENCLAW_GATEWAY_TOKEN="$(openssl rand -hex 32)"
  else
    OPENCLAW_GATEWAY_TOKEN="$(python3 -c 'import secrets; print(secrets.token_hex(32))')"
  fi
  # Replace any existing OPENCLAW_GATEWAY_TOKEN line(s) to avoid duplicate keys
  # (.env.raw.example already has OPENCLAW_GATEWAY_TOKEN=; appending would create a duplicate)
  if grep -q '^OPENCLAW_GATEWAY_TOKEN=' "$ENV_FILE" 2>/dev/null; then
    grep -v '^OPENCLAW_GATEWAY_TOKEN=' "$ENV_FILE" > "${ENV_FILE}.tmp"
    mv "${ENV_FILE}.tmp" "$ENV_FILE"
  fi
  echo "OPENCLAW_GATEWAY_TOKEN=$OPENCLAW_GATEWAY_TOKEN" >>"$ENV_FILE"
  info "Generated OPENCLAW_GATEWAY_TOKEN and wrote to .env"
fi

info "Done."
info "Config:      $OPENCLAW_CONFIG_DIR"
info "Workspaces:  $OPENCLAW_WORKSPACES_DIR"
echo ""
info "Start the gateway: ./openclaw-raw/scripts/gateway.sh"
info "Then get the dashboard URL: ./openclaw-raw/scripts/dashboard.sh"
echo ""
