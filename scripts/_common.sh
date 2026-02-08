#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
  docker compose -f "$ROOT_DIR/docker-compose.yml" -f "$ROOT_DIR/docker-compose.secure.yml" "$@"
}

compose_linux_hostnet() {
  docker compose \
    -f "$ROOT_DIR/docker-compose.yml" \
    -f "$ROOT_DIR/docker-compose.secure.yml" \
    -f "$ROOT_DIR/docker-compose.linux-hostnet.yml" \
    "$@"
}

compose_project_name() {
  # Default Compose project name is the directory name.
  basename "$ROOT_DIR"
}

is_gateway_hostnet_running() {
  # True if gateway container exists and runs with network_mode=host.
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
  # Auto-select the right compose stack.
  if ! is_macos && [[ -f "$ROOT_DIR/docker-compose.linux-hostnet.yml" ]] && is_gateway_hostnet_running; then
    compose_linux_hostnet "$@"
  else
    compose_base "$@"
  fi
}

load_env() {
  if [[ -f "$ROOT_DIR/.env" ]]; then
    # shellcheck disable=SC1091
    set -a && source "$ROOT_DIR/.env" && set +a
  fi
}

os_name() {
  uname -s | tr '[:upper:]' '[:lower:]'
}

is_macos() {
  [[ "$(os_name)" == "darwin" ]]
}

ensure_docker_running() {
  require_cmd docker
  if ! docker info >/dev/null 2>&1; then
    if is_macos; then
      die "Docker is installed but not running. Please start Docker Desktop, wait until it's ready, then re-run."
    fi
    die "Docker is installed but not running or you don't have permission. Start Docker, or run with sudo / add your user to the docker group."
  fi

  if ! docker compose version >/dev/null 2>&1; then
    die "Docker Compose v2 is not available. Install/enable 'docker compose'."
  fi
}
