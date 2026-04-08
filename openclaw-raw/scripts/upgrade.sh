#!/usr/bin/env bash
set -euo pipefail

# Upgrade native OpenClaw: update npm package, optionally sync config and workspace templates.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

load_env

SYNC_WORKSPACES=0
SYNC_CONFIG=0
DRY_RUN=0
CLEANUP_BOOTSTRAP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sync-workspaces)
      SYNC_WORKSPACES=1
      ;;
    --sync-config)
      SYNC_CONFIG=1
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    --cleanup-bootstrap)
      CLEANUP_BOOTSTRAP=1
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./openclaw-raw/scripts/upgrade.sh [options]

Options:
  --sync-workspaces    Overwrite changed workspace templates (creates .bak timestamped backups)
  --sync-config        Overwrite changed config templates (creates .bak timestamped backups)
  --dry-run            Print what workspace deployment would change
  --cleanup-bootstrap  Remove BOOTSTRAP.md from deployed workspaces (creates backup first)
  -h, --help           Show this help
EOF
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
  shift
done

require_cmd openclaw
require_cmd npm

OPENCLAW_WORKSPACES_DIR="${OPENCLAW_WORKSPACES_DIR:-$HOME/.openclaw/workspaces}"
OPENCLAW_CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
CONFIG_SRC="$REPO_ROOT/config/openclaw.json"

if [[ "$OPENCLAW_WORKSPACES_DIR" == "$HOME" || "$OPENCLAW_WORKSPACES_DIR" == "/" ]]; then
  die "Refusing unsafe workspaces root '$OPENCLAW_WORKSPACES_DIR'. Use a dedicated subdirectory."
fi

info "Upgrading OpenClaw (npm install -g openclaw)"
npm install -g openclaw

info "Upgrading Messy Virgo CLI (npm install -g @messyvirgo/cli@latest)"
npm install -g @messyvirgo/cli@latest

info "Ensuring config templates exist"
mkdir -p "$OPENCLAW_CONFIG_DIR"
ts="$(date +%Y%m%d-%H%M%S)"

if [[ -f "$CONFIG_SRC" ]]; then
  dest="$OPENCLAW_CONFIG_DIR/openclaw.json"
  if [[ ! -f "$dest" ]]; then
    cp "$CONFIG_SRC" "$dest"
    patch_openclaw_config_for_native "$dest"
    info "Wrote $dest (from config/openclaw.json + native patch)"
  elif [[ "$SYNC_CONFIG" == "1" ]]; then
    backup_path="$dest.bak.$ts"
    cp "$dest" "$backup_path"
    cp "$CONFIG_SRC" "$dest"
    patch_openclaw_config_for_native "$dest"
    info "Updated $dest (backup: $backup_path)"
  else
    tmp="$(mktemp)"
    cp "$CONFIG_SRC" "$tmp"
    PATCH_OC_QUIET=1 patch_openclaw_config_for_native "$tmp"
    if cmp -s "$tmp" "$dest"; then
      info "openclaw.json already up to date at $dest"
    else
      info "openclaw.json already exists at $dest (leaving untouched). Use --sync-config to overwrite."
    fi
    rm -f "$tmp"
  fi
fi

deploy_workspace_templates \
  "$REPO_ROOT" \
  "$OPENCLAW_WORKSPACES_DIR" \
  "$SYNC_WORKSPACES" \
  "$DRY_RUN" \
  "$CLEANUP_BOOTSTRAP"

info "Upgrade complete."
info "If the gateway is running, restart it to pick up changes: stop with Ctrl+C, then ./openclaw-raw/scripts/gateway.sh"
