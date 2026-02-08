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
  docker compose \
    -f "$ROOT_DIR/docker-compose.yml" \
    -f "$ROOT_DIR/docker-compose.secure.yml" \
    -f "$ROOT_DIR/docker-compose.ports.localhost.yml" \
    "$@"
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

# Docker Desktop on Mac often uses daemon API 1.44; Homebrew docker CLI may be 1.43.
# Force API 1.44 when unset on macOS so "docker info" and compose work.
if is_macos && [[ -z "${DOCKER_API_VERSION:-}" ]]; then
  export DOCKER_API_VERSION=1.44
fi
# On macOS, ensure Docker Desktop's bin is in PATH so docker-credential-desktop is found (for build/pull).
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
