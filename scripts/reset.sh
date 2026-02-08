#!/usr/bin/env bash
set -euo pipefail

# Project reset / fresh start helper.
#
# Safe by default: only stops/removes this project's containers + named volumes.
# Destructive actions (delete config/src/workspace, or docker system prune) require explicit flags
# and interactive confirmation (unless --yes is provided).
#
# Usage:
#   ./scripts/reset.sh
#   ./scripts/reset.sh --delete-config --delete-src
#   ./scripts/reset.sh --delete-config --delete-src --delete-workspace
#   ./scripts/reset.sh --system-prune
#
# Flags:
#   --delete-config     Delete OPENCLAW_CONFIG_DIR (OpenClaw config/state) after stopping containers
#   --delete-src        Delete OPENCLAW_SRC_DIR (OpenClaw source clone) after stopping containers
#   --delete-workspace  Delete OPENCLAW_WORKSPACE_DIR (your RW workspace) (extra confirmation)
#   --remove-image      Remove OPENCLAW_IMAGE (local image tag) if present
#   --system-prune      Run: docker system prune -a --volumes (VERY destructive)
#   -y, --yes           Non-interactive: assume "yes" for confirmations
#   -h, --help          Show help

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

usage() {
  sed -n '1,120p' "$0" | sed -n '1,120p' | sed 's/^# \{0,1\}//'
}

YES=0
DELETE_CONFIG=0
DELETE_SRC=0
DELETE_WORKSPACE=0
REMOVE_IMAGE=0
SYSTEM_PRUNE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --delete-config) DELETE_CONFIG=1; shift ;;
    --delete-src) DELETE_SRC=1; shift ;;
    --delete-workspace) DELETE_WORKSPACE=1; shift ;;
    --remove-image) REMOVE_IMAGE=1; shift ;;
    --system-prune) SYSTEM_PRUNE=1; shift ;;
    -y|--yes) YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown argument: $1 (use --help)" ;;
  esac
done

confirm() {
  local prompt="$1"
  if [[ "$YES" -eq 1 ]]; then
    return 0
  fi
  read -r -p "$prompt [y/N]: " yn || true
  [[ "${yn:-}" == "y" || "${yn:-}" == "Y" ]]
}

ensure_docker_running
load_env

ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw-secure}"
WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$HOME/OpenClawWorkspace}"
SRC_DIR="${OPENCLAW_SRC_DIR:-$CONFIG_DIR/openclaw-src}"
IMAGE_TAG="${OPENCLAW_IMAGE:-openclaw-secure:local}"

info "Reset scope: this project only (compose project: $(compose_project_name))"
info "Config dir:     $CONFIG_DIR"
info "Workspace dir:  $WORKSPACE_DIR"
info "Source dir:     $SRC_DIR"
info "Image tag:      $IMAGE_TAG"

echo ""
info "Stopping/removing this project's containers + volumes"
compose_base down -v --remove-orphans 2>/dev/null || true
if ! is_macos && [[ -f "$ROOT_DIR/docker-compose.linux-hostnet.yml" ]]; then
  compose_linux_hostnet down -v --remove-orphans 2>/dev/null || true
fi

if [[ "$REMOVE_IMAGE" -eq 1 ]]; then
  echo ""
  info "Removing image tag: $IMAGE_TAG"
  docker image rm -f "$IMAGE_TAG" >/dev/null 2>&1 || true
fi

if [[ "$DELETE_CONFIG" -eq 1 ]]; then
  echo ""
  if confirm "Delete config/state dir: $CONFIG_DIR ?"; then
    rm -rf "$CONFIG_DIR"
    info "Deleted: $CONFIG_DIR"
  else
    info "Skipped deleting config dir"
  fi
fi

if [[ "$DELETE_SRC" -eq 1 ]]; then
  echo ""
  if confirm "Delete source clone dir: $SRC_DIR ?"; then
    rm -rf "$SRC_DIR"
    info "Deleted: $SRC_DIR"
  else
    info "Skipped deleting source dir"
  fi
fi

if [[ "$DELETE_WORKSPACE" -eq 1 ]]; then
  echo ""
  echo "WARNING: This deletes your workspace (the only RW host folder OpenClaw uses)."
  echo "If you pointed the workspace at a real project directory, this will delete it."
  if confirm "Type 'y' to confirm deleting workspace: $WORKSPACE_DIR ?"; then
    if confirm "Last chance: really delete $WORKSPACE_DIR ?"; then
      rm -rf "$WORKSPACE_DIR"
      info "Deleted: $WORKSPACE_DIR"
    else
      info "Skipped deleting workspace dir"
    fi
  else
    info "Skipped deleting workspace dir"
  fi
fi

if [[ "$SYSTEM_PRUNE" -eq 1 ]]; then
  echo ""
  echo "DANGER: docker system prune -a --volumes removes ALL unused containers, networks, images, and volumes."
  echo "This affects your entire Docker system, not just this project."
  if confirm "Proceed with docker system prune -a --volumes ?"; then
    if confirm "Really proceed (this is destructive) ?"; then
      docker system prune -a --volumes
    else
      info "Skipped docker system prune"
    fi
  else
    info "Skipped docker system prune"
  fi
fi

echo ""
info "Reset complete."
info "Next: ./scripts/setup.sh"
info "Then:  ./scripts/up.sh && ./scripts/dashboard.sh"

