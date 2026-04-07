#!/usr/bin/env bash
set -euo pipefail

# Project reset / fresh start helper.
#
# Safe by default: only stops/removes this project's containers + named volumes.
# Destructive actions (delete config/src/workspace, or docker system prune) require explicit flags
# and interactive confirmation (unless --yes is provided).
#
# Usage:
#   ./openclaw-secure/scripts/reset.sh
#   ./openclaw-secure/scripts/reset.sh --delete-config --delete-src
#   ./openclaw-secure/scripts/reset.sh --delete-config --delete-src --delete-workspace
#   ./openclaw-secure/scripts/reset.sh --system-prune
#
# Flags:
#   --delete-config     Delete OPENCLAW_CONFIG_DIR (OpenClaw config/state) after stopping containers
#                       (default layout: this already removes workspaces under that tree; see --delete-workspace)
#   --delete-src        Delete OPENCLAW_SRC_DIR (OpenClaw source clone) after stopping containers
#   --delete-workspace  Delete OPENCLAW_WORKSPACE_DIR when it is outside the config dir (extra confirmation).
#                       Skipped automatically if --delete-config already removed the config tree containing it.
#   --remove-image      Remove OPENCLAW_IMAGE (local image tag) if present
#   --system-prune      Run: docker system prune -a --volumes (VERY destructive)
#   -y, --yes           Non-interactive: assume "yes" for confirmations
#   -h, --help          Show help

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

usage() {
  awk '
    NR == 1 { next }
    in_doc {
      if (/^#/) {
        sub(/^# ?/, "")
        print
        next
      }
      if (/^$/) next
      exit
    }
    /^#/ && !/^#!/ {
      in_doc = 1
      sub(/^# ?/, "")
      print
      next
    }
    { next }
  ' "$0"
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

# Best-effort absolute path for prefix checks (symlink-resolved when parent exists).
resolve_for_prefix_compare() {
  local p="${1:-}"
  [[ -n "$p" ]] || {
    echo ""
    return
  }
  if [[ -e "$p" ]]; then
    if [[ -d "$p" ]]; then
      (cd "$p" && pwd -P)
    else
      local parent dir_abs
      parent="$(dirname "$p")"
      dir_abs="$(cd "$parent" && pwd -P)"
      echo "${dir_abs}/$(basename "$p")"
    fi
  else
    local parent="${p%/*}"
    local base="${p##*/}"
    if [[ "$parent" == "$p" ]]; then
      echo "$p"
    elif [[ -d "$parent" ]]; then
      local resolved
      resolved="$(cd "$parent" && pwd -P)"
      echo "${resolved}/$base"
    else
      echo "${p%/}"
    fi
  fi
}

# True if workspace path is the config dir or inside it (so rm -rf config already removed it).
workspace_is_under_config_dir() {
  local root needle
  root="$(resolve_for_prefix_compare "$1")"
  needle="$(resolve_for_prefix_compare "$2")"
  [[ -n "$root" && -n "$needle" ]] || return 1
  root="${root%/}"
  needle="${needle%/}"
  [[ "$needle" == "$root" || "$needle" == "$root"/* ]]
}

ensure_docker_running
load_env

CONFIG_DIR="$(openclaw_host_config_dir)"
WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$HOME/.openclaw/workspaces/main}"
SRC_DIR="$(openclaw_host_src_dir)"
IMAGE_TAG="${OPENCLAW_IMAGE:-openclaw-secure:local}"

CONFIG_DELETED=0
WORKSPACE_CONTAINED_IN_CONFIG=0
if workspace_is_under_config_dir "$CONFIG_DIR" "$WORKSPACE_DIR"; then
  WORKSPACE_CONTAINED_IN_CONFIG=1
fi

if [[ "$SYSTEM_PRUNE" -eq 1 ]]; then
  info "Reset scope: this project + global Docker prune (compose project: $(compose_project_name))"
else
  info "Reset scope: this project only (compose project: $(compose_project_name))"
fi
info "Config dir:     $CONFIG_DIR"
info "Workspace dir:  $WORKSPACE_DIR"
info "Source dir:     $SRC_DIR"
info "Image tag:      $IMAGE_TAG"

echo ""
info "Stopping/removing this project's containers + volumes"
compose_base down -v --remove-orphans 2>/dev/null || true
if ! is_macos && [[ -f "$OPENCLAW_SECURE_ROOT/docker-compose.linux-hostnet.yml" ]]; then
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
    CONFIG_DELETED=1
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
  if [[ "$CONFIG_DELETED" -eq 1 && "$WORKSPACE_CONTAINED_IN_CONFIG" -eq 1 ]]; then
    echo ""
    info "Skipping workspace delete: $WORKSPACE_DIR (already removed with config dir $CONFIG_DIR)"
  else
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
fi

if [[ "$SYSTEM_PRUNE" -eq 1 ]]; then
  echo ""
  echo "DANGER: docker system prune -a --volumes removes ALL unused containers, networks, images, and volumes."
  echo "This affects your entire Docker system, not just this project."
  if confirm "Proceed with docker system prune -a --volumes ?"; then
    if confirm "Really proceed (this is destructive) ?"; then
      # We already run explicit confirmations above; use --force to avoid a third Docker prompt.
      docker system prune -a --volumes --force
    else
      info "Skipped docker system prune"
    fi
  else
    info "Skipped docker system prune"
  fi
fi

echo ""
info "Reset complete."

