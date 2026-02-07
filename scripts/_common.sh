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

compose() {
  # shellcheck disable=SC2068
  docker compose -f "$ROOT_DIR/docker-compose.yml" -f "$ROOT_DIR/docker-compose.secure.yml" ${@}
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
