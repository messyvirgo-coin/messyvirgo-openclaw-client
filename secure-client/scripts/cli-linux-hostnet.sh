#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

ensure_docker_running
load_env

if is_macos; then
  die "Host networking mode is Linux-only. Use ./scripts/cli.sh on macOS."
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <openclaw-cli-args...>"
  echo "Example: $0 health --json"
  exit 2
fi

docker compose \
  -f "$SECURE_CLIENT_ROOT/docker-compose.yml" \
  -f "$SECURE_CLIENT_ROOT/docker-compose.secure.yml" \
  -f "$SECURE_CLIENT_ROOT/docker-compose.linux-hostnet.yml" \
  -f "$SECURE_CLIENT_ROOT/docker-compose.skills.yml" \
  run --rm openclaw-cli "$@"
