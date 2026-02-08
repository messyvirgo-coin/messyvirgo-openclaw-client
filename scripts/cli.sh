#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

ensure_docker_running
load_env

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <openclaw-cli-args...>"
  echo "Example: $0 status"
  exit 2
fi

compose run --rm openclaw-cli "$@"
