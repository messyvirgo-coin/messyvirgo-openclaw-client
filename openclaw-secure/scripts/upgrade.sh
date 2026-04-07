#!/usr/bin/env bash
set -euo pipefail

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
      cat <<EOF
Usage: $0 [options]

Environment (from .env):
  OPENCLAW_GIT_REF   Git ref to check out after fetch (default: latest v* release tag).

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

if [[ -z "${OPENCLAW_GIT_REPO:-}" ]]; then
  OPENCLAW_GIT_REPO="https://github.com/openclaw/openclaw"
fi
if [[ -z "${OPENCLAW_NPM_VERSION:-}" ]]; then
  OPENCLAW_NPM_VERSION="11.11.1"
fi

OPENCLAW_CONFIG_DIR="$(openclaw_host_config_dir)"
OPENCLAW_SRC_DIR="$(openclaw_host_src_dir)"
if [[ -z "${OPENCLAW_WORKSPACES_DIR:-}" ]]; then
  if [[ -n "${OPENCLAW_WORKSPACE_DIR:-}" ]]; then
    LEGACY_PARENT_DIR="$(dirname "$OPENCLAW_WORKSPACE_DIR")"
    if [[ "$LEGACY_PARENT_DIR" == "$HOME" ]]; then
      OPENCLAW_WORKSPACES_DIR="$OPENCLAW_CONFIG_DIR/workspaces"
    else
      OPENCLAW_WORKSPACES_DIR="$LEGACY_PARENT_DIR"
    fi
  else
    OPENCLAW_WORKSPACES_DIR="$OPENCLAW_CONFIG_DIR/workspaces"
  fi
fi
if [[ "$OPENCLAW_WORKSPACES_DIR" == "$HOME" || "$OPENCLAW_WORKSPACES_DIR" == "/" ]]; then
  die "Refusing unsafe workspaces root '$OPENCLAW_WORKSPACES_DIR'. Use a dedicated subdirectory (for example $OPENCLAW_CONFIG_DIR/workspaces)."
fi

if [[ ! -d "$OPENCLAW_SRC_DIR/.git" ]]; then
  die "No git repo at $OPENCLAW_SRC_DIR. Run ${OPENCLAW_SECURE_ROOT}/scripts/setup.sh first."
fi

openclaw_sync_and_checkout_openclaw_source "$OPENCLAW_SRC_DIR" "$OPENCLAW_GIT_REPO"

info "Applying wrapper source patches"
"$SCRIPT_DIR/patch-openclaw-source.sh" "$OPENCLAW_SRC_DIR"

refresh_openclaw_pnpm_lockfile "$OPENCLAW_SRC_DIR"

info "Rebuilding Docker image ($OPENCLAW_IMAGE)"
OPENCLAW_DOCKER_BUILD_EXTRA_ARGS=()
if [[ -n "${OPENCLAW_NODE_BOOKWORM_IMAGE:-}" ]]; then
  OPENCLAW_DOCKER_BUILD_EXTRA_ARGS+=(--build-arg "OPENCLAW_NODE_BOOKWORM_IMAGE=$OPENCLAW_NODE_BOOKWORM_IMAGE")
  info "OpenClaw Dockerfile base: OPENCLAW_NODE_BOOKWORM_IMAGE=$OPENCLAW_NODE_BOOKWORM_IMAGE"
fi
docker build \
  --build-arg "OPENCLAW_DOCKER_APT_PACKAGES=${OPENCLAW_DOCKER_APT_PACKAGES:-jq}" \
  "${OPENCLAW_DOCKER_BUILD_EXTRA_ARGS[@]}" \
  -t "$OPENCLAW_IMAGE" \
  -f "$OPENCLAW_SRC_DIR/Dockerfile" \
  "$OPENCLAW_SRC_DIR"

info "Pinning npm in runtime image ($OPENCLAW_NPM_VERSION)"
docker build \
  --build-arg "BASE_IMAGE=$OPENCLAW_IMAGE" \
  --build-arg "OPENCLAW_NPM_VERSION=$OPENCLAW_NPM_VERSION" \
  -t "$OPENCLAW_IMAGE" \
  -f "$OPENCLAW_SECURE_ROOT/docker/npm-overlay.Dockerfile" \
  "$REPO_ROOT"

info "Ensuring config templates exist"
mkdir -p "$OPENCLAW_CONFIG_DIR"
chmod 700 "$OPENCLAW_CONFIG_DIR"
ts="$(date +%Y%m%d-%H%M%S)"
f="$REPO_ROOT/config/openclaw.json"
if [[ -f "$f" ]]; then
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
fi

deploy_workspace_templates \
  "$REPO_ROOT" \
  "$OPENCLAW_WORKSPACES_DIR" \
  "$SYNC_WORKSPACES" \
  "$DRY_RUN" \
  "$CLEANUP_BOOTSTRAP"

info "Restarting gateway"
compose down openclaw-gateway
compose up -d openclaw-gateway

if ! compose exec -T openclaw-gateway sh -lc 'command -v mcporter >/dev/null 2>&1'; then
  die "mcporter is missing in the runtime image. Re-run upgrade after pulling latest wrapper changes."
fi

info "Upgrade complete"
