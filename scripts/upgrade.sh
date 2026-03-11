#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"
load_env
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
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
Usage: ./scripts/upgrade.sh [options]

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

ensure_docker_running

if [[ -z "${OPENCLAW_SRC_DIR:-}" ]]; then
  die "OPENCLAW_SRC_DIR is not set. Run scripts/setup.sh first."
fi

DEFAULT_CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw-secure}"
if [[ -z "${OPENCLAW_WORKSPACES_DIR:-}" ]]; then
  if [[ -n "${OPENCLAW_WORKSPACE_DIR:-}" ]]; then
    LEGACY_PARENT_DIR="$(dirname "$OPENCLAW_WORKSPACE_DIR")"
    if [[ "$LEGACY_PARENT_DIR" == "$HOME" ]]; then
      OPENCLAW_WORKSPACES_DIR="$DEFAULT_CONFIG_DIR/workspaces"
    else
      OPENCLAW_WORKSPACES_DIR="$LEGACY_PARENT_DIR"
    fi
  elif [[ -n "${OPENCLAW_CONFIG_DIR:-}" ]]; then
    OPENCLAW_WORKSPACES_DIR="$HOME/OpenClawWorkspaces"
  else
    OPENCLAW_WORKSPACES_DIR="$HOME/OpenClawWorkspaces"
  fi
fi
if [[ "$OPENCLAW_WORKSPACES_DIR" == "$HOME" || "$OPENCLAW_WORKSPACES_DIR" == "/" ]]; then
  die "Refusing unsafe workspaces root '$OPENCLAW_WORKSPACES_DIR'. Use a dedicated subdirectory (for example $DEFAULT_CONFIG_DIR/workspaces)."
fi

if [[ ! -d "$OPENCLAW_SRC_DIR/.git" ]]; then
  die "No git repo at $OPENCLAW_SRC_DIR. Run scripts/setup.sh first."
fi

info "Pulling latest from fork"
git -C "$OPENCLAW_SRC_DIR" fetch --tags --prune
git -C "$OPENCLAW_SRC_DIR" checkout main
git -C "$OPENCLAW_SRC_DIR" pull --ff-only

info "Rebuilding Docker image ($OPENCLAW_IMAGE)"
docker build \
  --build-arg "OPENCLAW_DOCKER_APT_PACKAGES=${OPENCLAW_DOCKER_APT_PACKAGES:-jq}" \
  -t "$OPENCLAW_IMAGE" \
  -f "$OPENCLAW_SRC_DIR/Dockerfile" \
  "$OPENCLAW_SRC_DIR"

info "Ensuring config templates exist"
mkdir -p "$OPENCLAW_CONFIG_DIR"
chmod 700 "$OPENCLAW_CONFIG_DIR"
ts="$(date +%Y%m%d-%H%M%S)"
for f in "$ROOT_DIR"/config/openclaw*.json; do
  [[ -f "$f" ]] || continue
  dest="$OPENCLAW_CONFIG_DIR/$(basename "$f")"
  if [[ ! -f "$dest" ]]; then
    cp "$f" "$dest"
    info "Wrote $dest"
  elif cmp -s "$f" "$dest"; then
    info "$(basename "$f") already up to date at $dest"
  elif [[ "$SYNC_CONFIG" == "1" ]]; then
    backup_path="$dest.bak.$ts"
    cp "$dest" "$backup_path"
    cp "$f" "$dest"
    info "Updated $dest (backup: $backup_path)"
  else
    info "$(basename "$f") already exists at $dest (leaving untouched)"
  fi
done

deploy_workspace_templates \
  "$ROOT_DIR" \
  "$OPENCLAW_WORKSPACES_DIR" \
  "$SYNC_WORKSPACES" \
  "$DRY_RUN" \
  "$CLEANUP_BOOTSTRAP"

info "Restarting gateway"
compose down openclaw-gateway
compose up -d openclaw-gateway

info "Upgrade complete"
