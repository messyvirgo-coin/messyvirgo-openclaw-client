#!/usr/bin/env bash
set -euo pipefail

# Bootstrap native (non-Docker) OpenClaw with this repo's config.
# Prerequisite: OpenClaw installed (npm i -g openclaw or equivalent).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

require_cmd openclaw

ENV_FILE="$REPO_ROOT/.env"
CONFIG_SRC="$REPO_ROOT/config/openclaw.native.json"

# Ensure .env exists
if [[ ! -f "$ENV_FILE" ]]; then
  if [[ -f "$REPO_ROOT/.env.example" ]]; then
    cp "$REPO_ROOT/.env.example" "$ENV_FILE"
    info "Created $ENV_FILE from .env.example"
  else
    die "Missing .env.example. Create .env with OPENCLAW_WORKSPACES_DIR, OPENCLAW_SKILLS_DIR, API keys, and OPENCLAW_GATEWAY_TOKEN."
  fi
fi

load_env

# Required for native config
if [[ -z "${OPENCLAW_WORKSPACES_DIR:-}" ]]; then
  OPENCLAW_WORKSPACES_DIR="${HOME:-}/OpenClawWorkspaces"
  info "Using default OPENCLAW_WORKSPACES_DIR=$OPENCLAW_WORKSPACES_DIR (add to .env to override)"
fi
OPENCLAW_SKILLS_DIR="$(resolve_openclaw_skills_dir "${OPENCLAW_SKILLS_DIR:-}")"
if [[ -z "${OPENCLAW_CONFIG_DIR:-}" ]]; then
  OPENCLAW_CONFIG_DIR="${HOME:-}/.openclaw"
  info "Using default OPENCLAW_CONFIG_DIR=$OPENCLAW_CONFIG_DIR (add to .env to override)"
fi

mkdir -p "$OPENCLAW_CONFIG_DIR"
mkdir -p "$OPENCLAW_WORKSPACES_DIR"

# Deploy native config (openclaw.native.json uses ${OPENCLAW_*} env vars)
dest="$OPENCLAW_CONFIG_DIR/openclaw.json"
if [[ ! -f "$dest" ]]; then
  cp "$CONFIG_SRC" "$dest"
  info "Wrote $dest (from config/openclaw.native.json)"
else
  info "$dest already exists (leaving untouched). To refresh: cp $CONFIG_SRC $dest"
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
  # Append to .env
  echo "OPENCLAW_GATEWAY_TOKEN=$OPENCLAW_GATEWAY_TOKEN" >>"$ENV_FILE"
  info "Generated OPENCLAW_GATEWAY_TOKEN and appended to .env"
fi

info "Done."
info "Config:      $OPENCLAW_CONFIG_DIR"
info "Workspaces:  $OPENCLAW_WORKSPACES_DIR"
info "Skills:      $OPENCLAW_SKILLS_DIR"
echo ""
info "Start the gateway: ./openclaw-raw/scripts/gateway.sh"
info "Then get the dashboard URL: ./openclaw-raw/scripts/dashboard.sh"
echo ""
