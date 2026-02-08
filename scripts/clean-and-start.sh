#!/usr/bin/env bash
set -euo pipefail

# Remove all Docker artefacts from this project, then run full setup and start.
# Usage: ./scripts/clean-and-start.sh
# Prerequisite: Docker Desktop running (docker info must succeed).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

ensure_docker_running
require_cmd git

# Load .env so compose project and vars are correct
if [[ ! -f "$ENV_FILE" ]]; then
  die "No .env found. Run ./scripts/setup.sh first (it creates .env from .env.example)."
fi
load_env

# ---- Remove all previous Docker artefacts ----
info "Stopping and removing OpenClaw containers and volumes"
docker compose -f "$ROOT_DIR/docker-compose.yml" -f "$ROOT_DIR/docker-compose.secure.yml" down -v --remove-orphans 2>/dev/null || true

# On Linux, also tear down hostnet stack if it was used
if ! is_macos && [[ -f "$ROOT_DIR/docker-compose.linux-hostnet.yml" ]]; then
  docker compose \
    -f "$ROOT_DIR/docker-compose.yml" \
    -f "$ROOT_DIR/docker-compose.secure.yml" \
    -f "$ROOT_DIR/docker-compose.linux-hostnet.yml" \
    down -v --remove-orphans 2>/dev/null || true
fi

info "Docker artefacts removed."

# ---- Ensure dirs ----
mkdir -p "$OPENCLAW_CONFIG_DIR"
mkdir -p "$OPENCLAW_WORKSPACE_DIR"
mkdir -p "$(dirname "$OPENCLAW_SRC_DIR")"

# ---- Clone/update OpenClaw source ----
info "Cloning/updating OpenClaw source"
if [[ -d "${OPENCLAW_SRC_DIR:-}/.git" ]]; then
  git -C "$OPENCLAW_SRC_DIR" fetch --tags --prune
  git -C "$OPENCLAW_SRC_DIR" checkout main
  git -C "$OPENCLAW_SRC_DIR" pull --ff-only
else
  rm -rf "${OPENCLAW_SRC_DIR:-}"
  git clone https://github.com/openclaw/openclaw.git "$OPENCLAW_SRC_DIR"
fi

# ---- Build image ----
info "Building Docker image ($OPENCLAW_IMAGE)"
docker build \
  --build-arg "OPENCLAW_DOCKER_APT_PACKAGES=${OPENCLAW_DOCKER_APT_PACKAGES:-}" \
  -t "$OPENCLAW_IMAGE" \
  -f "$OPENCLAW_SRC_DIR/Dockerfile" \
  "$OPENCLAW_SRC_DIR"

# ---- Config: use template if present and no config yet ----
if [[ -f "$ROOT_DIR/config/openclaw.secure.json" ]] && [[ ! -f "$OPENCLAW_CONFIG_DIR/openclaw.json" ]]; then
  cp "$ROOT_DIR/config/openclaw.secure.json" "$OPENCLAW_CONFIG_DIR/openclaw.json"
  info "Wrote $OPENCLAW_CONFIG_DIR/openclaw.json"
fi

# ---- Onboarding only if no config ----
if [[ ! -f "$OPENCLAW_CONFIG_DIR/openclaw.json" ]]; then
  info "Running OpenClaw onboarding (interactive)"
  info "Suggested: Gateway bind=lan, auth=token, token from .env, Tailscale=Off, Install daemon=No"
  compose_base run --rm openclaw-cli onboard --no-install-daemon
else
  info "Config already exists at $OPENCLAW_CONFIG_DIR/openclaw.json (skipping onboarding)"
fi

# ---- Start gateway ----
info "Starting OpenClaw gateway"
set +e
OUT="$(compose_base up -d openclaw-gateway 2>&1)"
CODE=$?
set -e
if [[ $CODE -ne 0 ]]; then
  echo "$OUT" >&2
  if ! is_macos && echo "$OUT" | grep -q "failed to bind host port" && [[ -f "$ROOT_DIR/docker-compose.linux-hostnet.yml" ]]; then
    echo "" >&2
    echo "Port publishing failed on Linux; using host networking workaround." >&2
    OPENCLAW_GATEWAY_BIND=loopback compose_linux_hostnet up -d openclaw-gateway
  else
    exit "$CODE"
  fi
fi

info "Done."
info "Dashboard (localhost-only): http://127.0.0.1:${OPENCLAW_GATEWAY_PORT:-18789}/"
info "Run ./scripts/dashboard.sh for a tokenized dashboard URL."
