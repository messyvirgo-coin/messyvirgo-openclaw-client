#!/usr/bin/env bash
set -euo pipefail

# OpenClaw-secure scripts live in openclaw-secure/scripts/; repo root is parent of openclaw-secure
OPENCLAW_SECURE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$OPENCLAW_SECURE_ROOT/.." && pwd)"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

info() {
  echo "==> $*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing dependency: $1"
}

compose_base() {
  docker compose \
    -f "$OPENCLAW_SECURE_ROOT/docker-compose.yml" \
    -f "$OPENCLAW_SECURE_ROOT/docker-compose.secure.yml" \
    -f "$OPENCLAW_SECURE_ROOT/docker-compose.ports.localhost.yml" \
    "$@"
}

compose_linux_hostnet() {
  # Host networking uses the host netns; published-port maps do not apply. Force a
  # loopback bind so the gateway stays localhost-only despite OPENCLAW_GATEWAY_BIND=lan in .env.
  OPENCLAW_GATEWAY_BIND=loopback docker compose \
    -f "$OPENCLAW_SECURE_ROOT/docker-compose.yml" \
    -f "$OPENCLAW_SECURE_ROOT/docker-compose.secure.yml" \
    -f "$OPENCLAW_SECURE_ROOT/docker-compose.linux-hostnet.yml" \
    "$@"
}

compose_project_name() {
  basename "$OPENCLAW_SECURE_ROOT"
}

is_gateway_hostnet_running() {
  local proj cid
  proj="$(compose_project_name)"
  cid="$(docker ps -a \
    --filter "label=com.docker.compose.project=${proj}" \
    --filter "label=com.docker.compose.service=openclaw-gateway" \
    -q | head -n 1 || true)"
  if [[ -z "${cid:-}" ]]; then
    return 1
  fi
  [[ "$(docker inspect -f '{{.HostConfig.NetworkMode}}' "$cid" 2>/dev/null || true)" == "host" ]]
}

compose() {
  if ! is_macos && [[ -f "$OPENCLAW_SECURE_ROOT/docker-compose.linux-hostnet.yml" ]]; then
    compose_linux_hostnet "$@"
  else
    compose_base "$@"
  fi
}

load_env() {
  if [[ -f "$REPO_ROOT/.env" ]]; then
    # shellcheck disable=SC1091
    set -a && source "$REPO_ROOT/.env" && set +a
  fi
}

# Host directory for OpenClaw config/state (mounted to /home/node/.openclaw in Docker). Call after
# load_env. Override with OPENCLAW_CONFIG_DIR in repo root `.env` (e.g. a second install:
# $HOME/.openclaw-staging).
openclaw_host_config_dir() {
  echo "${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
}

# Upstream OpenClaw git clone used for Docker builds. Optional in `.env`; default is beside config:
# $(openclaw_host_config_dir)/openclaw-src
openclaw_host_src_dir() {
  echo "${OPENCLAW_SRC_DIR:-$(openclaw_host_config_dir)/openclaw-src}"
}

dir_owner_uid() {
  local dir="$1"
  if stat -c '%u' "$dir" >/dev/null 2>&1; then
    stat -c '%u' "$dir"
  else
    stat -f '%u' "$dir"
  fi
}

ensure_host_dir_writable() {
  local dir="$1"
  local label="${2:-directory}"
  local auto_fix="${3:-0}"
  [[ -n "$dir" ]] || die "ensure_host_dir_writable: missing directory path for $label"

  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir" 2>/dev/null || true
  fi
  if [[ ! -d "$dir" ]]; then
    die "Could not create $label at '$dir' (permission denied). Fix: sudo mkdir -p \"$dir\" && sudo chown -R \"$USER:$USER\" \"$dir\""
  fi

  local my_uid owner_uid
  my_uid="$(id -u)"
  owner_uid="$(dir_owner_uid "$dir" 2>/dev/null || echo "")"
  if [[ "$auto_fix" == "1" && "$owner_uid" != "$my_uid" ]]; then
    local target_user target_group
    target_user="${SUDO_USER:-$USER}"
    target_group="$target_user"
    if [[ "$EUID" -eq 0 ]]; then
      chown -R "$target_user:$target_group" "$dir" 2>/dev/null || true
    elif command -v sudo >/dev/null 2>&1; then
      info "Fixing ownership for $label at '$dir' (sudo may prompt)"
      sudo chown -R "$target_user:$target_group" "$dir" 2>/dev/null || true
    fi
  fi

  if [[ ! -w "$dir" ]]; then
    local perms
    perms="$(ls -ld "$dir" 2>/dev/null || true)"
    die "$label is not writable at '$dir'.${perms:+ Current permissions: $perms.} Fix: sudo chown -R \"$USER:$USER\" \"$dir\""
  fi
}

os_name() {
  uname -s | tr '[:upper:]' '[:lower:]'
}

is_macos() {
  [[ "$(os_name)" == "darwin" ]]
}

# Docker Desktop on Mac often uses daemon API 1.44; Homebrew docker CLI may be 1.43.
if is_macos && [[ -z "${DOCKER_API_VERSION:-}" ]]; then
  export DOCKER_API_VERSION=1.44
fi
if is_macos && [[ -d /Applications/Docker.app/Contents/Resources/bin ]]; then
  export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
fi

ensure_docker_running() {
  require_cmd docker
  if ! docker info >/dev/null 2>&1; then
    if is_macos; then
      echo "ERROR: Docker is not responding. The CLI is installed but 'docker info' failed." >&2
      echo "" >&2
      echo "Docker Desktop troubleshooting:" >&2
      echo "  1. In Docker Desktop, ensure the engine is running (whale icon in menu bar)." >&2
      echo "  2. Docker menu → Troubleshoot → Restart Docker Desktop; wait until it says running." >&2
      echo "  3. If it still fails: Troubleshoot → Clean / Purge data (resets data, keeps settings)." >&2
      echo "  4. In terminal, ensure context is Docker Desktop: docker context use desktop-linux" >&2
      echo "  5. Run: docker info   (if you see 'Server:' and no ERROR, Docker is ready)." >&2
      echo "" >&2
      die "Docker is not ready. Fix the above and re-run."
    fi
    die "Docker is installed but not running or you don't have permission. Start Docker, or run with sudo / add your user to the docker group."
  fi

  if ! docker compose version >/dev/null 2>&1; then
    die "Docker Compose v2 is not available. Install/enable 'docker compose'."
  fi
}

# Host `pnpm install` refreshes the lockfile before `docker build` (avoids ERR_PNPM_OUTDATED_LOCKFILE under CI prune).
refresh_openclaw_pnpm_lockfile() {
  local src="${1:?}"
  if ! command -v pnpm >/dev/null 2>&1; then
    info "pnpm not on PATH; on ERR_PNPM_OUTDATED_LOCKFILE run (cd \"$src\" && corepack enable && pnpm install)"
    return 0
  fi
  info "Refreshing pnpm lockfile in OpenClaw source"
  (
    cd "$src" || exit 1
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    corepack enable >/dev/null 2>&1 || true
    pnpm install
  ) || die "pnpm install failed in $src (could not refresh lockfile)"
}

# Fetch origin; check out OPENCLAW_GIT_REF if set, else newest v* tag (aligned with upgrade.sh).
openclaw_sync_and_checkout_openclaw_source() {
  local src="${1:?}"
  local repo="${2:?}"
  info "Fetching OpenClaw ($repo)"
  git -C "$src" remote set-url origin "$repo"
  git -C "$src" fetch --tags --prune origin
  if [[ -n "${OPENCLAW_GIT_REF:-}" ]]; then
    info "Checking out $OPENCLAW_GIT_REF"
    git -C "$src" -c advice.detachedHead=false checkout --force "$OPENCLAW_GIT_REF"
    if git -C "$src" rev-parse "origin/${OPENCLAW_GIT_REF}" >/dev/null 2>&1; then
      git -C "$src" reset --hard "origin/${OPENCLAW_GIT_REF}"
    fi
  else
    local tag
    tag="$(git -C "$src" tag -l 'v*' --sort=-v:refname | head -n 1)"
    if [[ -z "$tag" ]]; then
      die "No v* release tags in $src. Set OPENCLAW_GIT_REF in .env (e.g. main)."
    fi
    info "Checking out $tag"
    git -C "$src" -c advice.detachedHead=false checkout --force "$tag"
  fi
  info "OpenClaw $(git -C "$src" log -1 --oneline)"
}

workspace_dir_for_agent() {
  local workspace_root="$1"
  local agent_id="$2"
  echo "$workspace_root/$agent_id"
}

sync_directory_contents() {
  local source_dir="$1"
  local target_dir="$2"
  local sync_mode="${3:-0}"
  local dry_run="${4:-0}"
  local ts="$5"
  local label="${6:-assets}"

  [[ -d "$source_dir" ]] || return 0

  if [[ "$dry_run" == "1" ]]; then
    info "[dry-run] would ensure $label dir: $target_dir"
  else
    mkdir -p "$target_dir"
  fi

  local src
  for src in "$source_dir"/*; do
    [[ -e "$src" ]] || continue
    local name dest
    name="$(basename "$src")"
    dest="$target_dir/$name"

    if [[ ! -e "$dest" ]]; then
      if [[ "$dry_run" == "1" ]]; then
        info "[dry-run] would create $dest"
      else
        cp -R "$src" "$dest"
        info "Wrote $dest"
      fi
      continue
    fi

    if cmp -s "$src" "$dest" 2>/dev/null; then
      info "$label item already up to date at $target_dir"
      continue
    fi

    if [[ "$sync_mode" == "1" ]]; then
      local backup_path
      backup_path="$dest.bak.$ts"
      if [[ "$dry_run" == "1" ]]; then
        info "[dry-run] would backup $dest -> $backup_path"
        info "[dry-run] would overwrite $dest from $source_dir"
      else
        cp -R "$dest" "$backup_path"
        rm -rf "$dest"
        cp -R "$src" "$dest"
        info "Updated $dest (backup: $backup_path)"
      fi
    else
      info "$dest already exists (leaving untouched)"
    fi
  done
}

deploy_workspace_templates() {
  local repo_root="$1"
  local workspace_root="$2"
  local sync_workspaces="${3:-0}"
  local dry_run="${4:-0}"
  local cleanup_bootstrap="${5:-0}"
  local ts
  ts="$(date +%Y%m%d-%H%M%S)"

  info "Deploying workspace templates"
  for agent_dir in "$repo_root"/config/workspaces/*/; do
    [[ -d "$agent_dir" ]] || continue
    local agent_id target_dir
    agent_id="$(basename "$agent_dir")"
    target_dir="$(workspace_dir_for_agent "$workspace_root" "$agent_id")"

    if [[ "$dry_run" == "1" ]]; then
      info "[dry-run] would ensure workspace dir: $target_dir"
    else
      mkdir -p "$target_dir"
    fi

    for f in "$agent_dir"*.md; do
      [[ -f "$f" ]] || continue
      local dest file_name
      file_name="$(basename "$f")"
      dest="$target_dir/$file_name"

      if [[ ! -f "$dest" ]]; then
        if [[ "$dry_run" == "1" ]]; then
          info "[dry-run] would create $dest"
        else
          cp "$f" "$dest"
          info "Wrote $dest"
        fi
        continue
      fi

      if cmp -s "$f" "$dest"; then
        info "$file_name already up to date at $target_dir"
        continue
      fi

      if [[ "$sync_workspaces" == "1" ]]; then
        local backup_path
        backup_path="$dest.bak.$ts"
        if [[ "$dry_run" == "1" ]]; then
          info "[dry-run] would backup $dest -> $backup_path"
          info "[dry-run] would overwrite $dest from template"
        else
          cp "$dest" "$backup_path"
          cp "$f" "$dest"
          info "Updated $dest (backup: $backup_path)"
        fi
      else
        info "$file_name already exists at $target_dir (leaving untouched)"
      fi
    done

    if [[ "$cleanup_bootstrap" == "1" ]]; then
      local bootstrap_path
      bootstrap_path="$target_dir/BOOTSTRAP.md"
      if [[ -f "$bootstrap_path" ]]; then
        local bootstrap_backup
        bootstrap_backup="$bootstrap_path.bak.$ts"
        if [[ "$dry_run" == "1" ]]; then
          info "[dry-run] would backup and remove $bootstrap_path"
        else
          cp "$bootstrap_path" "$bootstrap_backup"
          rm -f "$bootstrap_path"
          info "Removed $bootstrap_path (backup: $bootstrap_backup)"
        fi
      fi
    fi

    sync_directory_contents \
      "$repo_root/assets/avatars/$agent_id" \
      "$target_dir/avatars" \
      "$sync_workspaces" \
      "$dry_run" \
      "$ts" \
      "avatar ($agent_id)"
  done
}
