#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"
load_env

ensure_docker_running

if [[ -z "${OPENCLAW_SRC_DIR:-}" ]]; then
  die "OPENCLAW_SRC_DIR is not set. Run scripts/setup.sh first."
fi

if [[ ! -d "$OPENCLAW_SRC_DIR/.git" ]]; then
  die "No git repo at $OPENCLAW_SRC_DIR. Run scripts/setup.sh first."
fi

info "Pulling latest from fork"
git -C "$OPENCLAW_SRC_DIR" fetch --tags --prune
git -C "$OPENCLAW_SRC_DIR" checkout main
git -C "$OPENCLAW_SRC_DIR" pull --ff-only

info "Rebuilding Docker image ($OPENCLAW_IMAGE)"
docker build \
  --build-arg "OPENCLAW_DOCKER_APT_PACKAGES=${OPENCLAW_DOCKER_APT_PACKAGES:-}" \
  -t "$OPENCLAW_IMAGE" \
  -f "$OPENCLAW_SRC_DIR/Dockerfile" \
  "$OPENCLAW_SRC_DIR"

info "Restarting gateway"
compose down openclaw-gateway
compose up -d openclaw-gateway

info "Upgrade complete"
