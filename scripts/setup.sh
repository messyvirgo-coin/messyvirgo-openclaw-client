#!/usr/bin/env bash
set -euo pipefail

# Interactive bootstrap for Linux + macOS (Docker Desktop)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

require_cmd git

ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

prompt_default() {
  local prompt="$1"
  local def="$2"
  local out
  read -r -p "$prompt [$def]: " out || true
  if [[ -z "${out:-}" ]]; then
    echo "$def"
  else
    echo "$out"
  fi
}

random_hex_64() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
    return
  fi
  python3 - <<'PY'
import secrets
print(secrets.token_hex(32))
PY
}

ensure_docker_running

info "Preparing .env"
if [[ ! -f "$ENV_FILE" ]]; then
  if [[ -f "$ROOT_DIR/.env.example" ]]; then
    cp "$ROOT_DIR/.env.example" "$ENV_FILE"
  else
    die "Missing .env.example (repo incomplete)."
  fi
fi

# Load current values (if any) so we can prompt with them
load_env

DEFAULT_CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw-secure}"
DEFAULT_WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$HOME/OpenClawWorkspace}"
DEFAULT_SRC_DIR="${OPENCLAW_SRC_DIR:-$DEFAULT_CONFIG_DIR/openclaw-src}"
DEFAULT_IMAGE="${OPENCLAW_IMAGE:-openclaw-secure:local}"

OPENCLAW_CONFIG_DIR="$(prompt_default "Host config/state directory" "$DEFAULT_CONFIG_DIR")"
OPENCLAW_WORKSPACE_DIR="$(prompt_default "Host workspace directory (RW)" "$DEFAULT_WORKSPACE_DIR")"
OPENCLAW_SRC_DIR="$(prompt_default "Where to clone OpenClaw source (for building)" "$DEFAULT_SRC_DIR")"
OPENCLAW_IMAGE="$(prompt_default "Docker image tag to build" "$DEFAULT_IMAGE")"

mkdir -p "$OPENCLAW_CONFIG_DIR"
mkdir -p "$OPENCLAW_WORKSPACE_DIR"
mkdir -p "$(dirname "$OPENCLAW_SRC_DIR")"

if [[ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]]; then
  OPENCLAW_GATEWAY_TOKEN="$(random_hex_64)"
fi

# Write .env (simple overwrite, deterministic keys)
cat >"$ENV_FILE" <<EOF
OPENCLAW_CONFIG_DIR=$OPENCLAW_CONFIG_DIR
OPENCLAW_WORKSPACE_DIR=$OPENCLAW_WORKSPACE_DIR
OPENCLAW_GATEWAY_PORT=${OPENCLAW_GATEWAY_PORT:-18789}
OPENCLAW_BRIDGE_PORT=${OPENCLAW_BRIDGE_PORT:-18790}
OPENCLAW_GATEWAY_BIND=${OPENCLAW_GATEWAY_BIND:-lan}
OPENCLAW_IMAGE=$OPENCLAW_IMAGE
OPENCLAW_GATEWAY_TOKEN=$OPENCLAW_GATEWAY_TOKEN
OPENCLAW_DOCKER_APT_PACKAGES=${OPENCLAW_DOCKER_APT_PACKAGES:-}
OPENCLAW_SRC_DIR=$OPENCLAW_SRC_DIR
EOF

info "Cloning/updating OpenClaw source"
if [[ -d "$OPENCLAW_SRC_DIR/.git" ]]; then
  git -C "$OPENCLAW_SRC_DIR" fetch --tags --prune
  git -C "$OPENCLAW_SRC_DIR" checkout main
  git -C "$OPENCLAW_SRC_DIR" pull --ff-only
else
  rm -rf "$OPENCLAW_SRC_DIR"
  git clone https://github.com/openclaw/openclaw.git "$OPENCLAW_SRC_DIR"
fi

info "Building Docker image ($OPENCLAW_IMAGE)"
docker build \
  --build-arg "OPENCLAW_DOCKER_APT_PACKAGES=${OPENCLAW_DOCKER_APT_PACKAGES:-}" \
  -t "$OPENCLAW_IMAGE" \
  -f "$OPENCLAW_SRC_DIR/Dockerfile" \
  "$OPENCLAW_SRC_DIR"

info "Copying secure config template (if missing)"
if [[ -f "$ROOT_DIR/config/openclaw.secure.json" ]]; then
  mkdir -p "$OPENCLAW_CONFIG_DIR"
  if [[ ! -f "$OPENCLAW_CONFIG_DIR/openclaw.json" ]]; then
    cp "$ROOT_DIR/config/openclaw.secure.json" "$OPENCLAW_CONFIG_DIR/openclaw.json"
    info "Wrote $OPENCLAW_CONFIG_DIR/openclaw.json"
  else
    info "Config already exists at $OPENCLAW_CONFIG_DIR/openclaw.json (leaving it untouched)"
  fi
else
  info "Secure config template not present yet; continuing without it."
fi

info "Running OpenClaw onboarding (interactive)"
info "Suggested answers:"
info " - Gateway bind: lan"
info " - Gateway auth: token"
info " - Gateway token: (already set in .env)"
info " - Tailscale exposure: Off"
info " - Install Gateway daemon: No (we run via Docker)"
compose run --rm openclaw-cli onboard --no-install-daemon

info "Starting gateway"
compose up -d openclaw-gateway

info "Done."
info "Workspace (RW): $OPENCLAW_WORKSPACE_DIR"
info "Config/state:    $OPENCLAW_CONFIG_DIR"
info "Dashboard:       http://127.0.0.1:${OPENCLAW_GATEWAY_PORT:-18789}/"
info "Next: run ./scripts/dashboard.sh to get a tokenized dashboard URL."
