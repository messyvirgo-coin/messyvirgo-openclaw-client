#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

ensure_docker_running
load_env

echo "Break-glass root shell inside gateway container."
echo "Tip: prefer baking packages into the image via OPENCLAW_DOCKER_APT_PACKAGES in .env."
compose exec -u root openclaw-gateway bash
