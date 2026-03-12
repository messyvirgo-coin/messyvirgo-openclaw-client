#!/usr/bin/env bash
set -euo pipefail

# Interactive bootstrap for Linux + macOS (Docker Desktop)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

require_cmd git

ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
SYNC_WORKSPACES=0
DRY_RUN=0
CLEANUP_BOOTSTRAP=0
INTERACTIVE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sync-workspaces)
      SYNC_WORKSPACES=1
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    --cleanup-bootstrap)
      CLEANUP_BOOTSTRAP=1
      ;;
    --interactive)
      INTERACTIVE=1
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./scripts/setup.sh [options]

Options:
  --sync-workspaces    Overwrite changed workspace templates (creates .bak timestamped backups)
  --dry-run            Print what workspace deployment would change
  --cleanup-bootstrap  Remove BOOTSTRAP.md from deployed workspaces (creates backup first)
  --interactive        Prompt for config values instead of using .env/defaults
  -h, --help           Show this help
EOF
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
  shift
done

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
if [[ -n "${OPENCLAW_WORKSPACES_DIR:-}" ]]; then
  DEFAULT_WORKSPACES_DIR="$OPENCLAW_WORKSPACES_DIR"
elif [[ -n "${OPENCLAW_WORKSPACE_DIR:-}" ]]; then
  LEGACY_PARENT_DIR="$(dirname "$OPENCLAW_WORKSPACE_DIR")"
  if [[ "$LEGACY_PARENT_DIR" == "$HOME" ]]; then
    DEFAULT_WORKSPACES_DIR="$DEFAULT_CONFIG_DIR/workspaces"
  else
    DEFAULT_WORKSPACES_DIR="$LEGACY_PARENT_DIR"
  fi
else
  DEFAULT_WORKSPACES_DIR="$HOME/OpenClawWorkspaces"
fi
DEFAULT_SRC_DIR="${OPENCLAW_SRC_DIR:-$DEFAULT_CONFIG_DIR/openclaw-src}"
DEFAULT_GIT_REPO="${OPENCLAW_GIT_REPO:-https://github.com/messyvirgo-coin/messyvirgo-openclaw}"
DEFAULT_IMAGE="${OPENCLAW_IMAGE:-openclaw-secure:local}"

if [[ "$INTERACTIVE" == "1" ]]; then
  OPENCLAW_CONFIG_DIR="$(prompt_default "Host config/state directory" "$DEFAULT_CONFIG_DIR")"
  OPENCLAW_WORKSPACES_DIR="$(prompt_default "Host root directory for per-agent workspaces" "$DEFAULT_WORKSPACES_DIR")"
  OPENCLAW_SRC_DIR="$(prompt_default "Where to clone OpenClaw source (for building)" "$DEFAULT_SRC_DIR")"
  OPENCLAW_GIT_REPO="$(prompt_default "OpenClaw Git repo URL to clone/pull" "$DEFAULT_GIT_REPO")"
  OPENCLAW_IMAGE="$(prompt_default "Docker image tag to build" "$DEFAULT_IMAGE")"
else
  OPENCLAW_CONFIG_DIR="$DEFAULT_CONFIG_DIR"
  OPENCLAW_WORKSPACES_DIR="$DEFAULT_WORKSPACES_DIR"
  OPENCLAW_SRC_DIR="$DEFAULT_SRC_DIR"
  OPENCLAW_GIT_REPO="$DEFAULT_GIT_REPO"
  OPENCLAW_IMAGE="$DEFAULT_IMAGE"
fi
if [[ "$OPENCLAW_WORKSPACES_DIR" == "$HOME" || "$OPENCLAW_WORKSPACES_DIR" == "/" ]]; then
  die "Refusing unsafe workspaces root '$OPENCLAW_WORKSPACES_DIR'. Use a dedicated subdirectory (for example $DEFAULT_CONFIG_DIR/workspaces)."
fi
OPENCLAW_WORKSPACE_DIR="$OPENCLAW_WORKSPACES_DIR/main"

mkdir -p "$OPENCLAW_CONFIG_DIR"
chmod 700 "$OPENCLAW_CONFIG_DIR"
mkdir -p "$OPENCLAW_WORKSPACES_DIR"
mkdir -p "$(dirname "$OPENCLAW_SRC_DIR")"

if [[ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]]; then
  OPENCLAW_GATEWAY_TOKEN="$(random_hex_64)"
fi

# Write .env (simple overwrite, deterministic keys)
cat >"$ENV_FILE" <<EOF
BANKR_API_KEY=${BANKR_API_KEY:-}
OPENROUTER_API_KEY=${OPENROUTER_API_KEY:-}
BRAVE_API_KEY=${BRAVE_API_KEY:-}
OPENCLAW_CONFIG_DIR=$OPENCLAW_CONFIG_DIR
OPENCLAW_WORKSPACES_DIR=$OPENCLAW_WORKSPACES_DIR
OPENCLAW_WORKSPACE_DIR=$OPENCLAW_WORKSPACE_DIR
OPENCLAW_GATEWAY_PORT=${OPENCLAW_GATEWAY_PORT:-18789}
OPENCLAW_BRIDGE_PORT=${OPENCLAW_BRIDGE_PORT:-18790}
OPENCLAW_GATEWAY_BIND=${OPENCLAW_GATEWAY_BIND:-lan}
OPENCLAW_IMAGE=$OPENCLAW_IMAGE
OPENCLAW_GATEWAY_TOKEN=$OPENCLAW_GATEWAY_TOKEN
OPENCLAW_DOCKER_APT_PACKAGES=${OPENCLAW_DOCKER_APT_PACKAGES:-jq}
OPENCLAW_SRC_DIR=$OPENCLAW_SRC_DIR
OPENCLAW_GIT_REPO=$OPENCLAW_GIT_REPO
EOF

info "Cloning/updating OpenClaw source"
if [[ -d "$OPENCLAW_SRC_DIR/.git" ]]; then
  git -C "$OPENCLAW_SRC_DIR" remote set-url origin "$OPENCLAW_GIT_REPO"
  git -C "$OPENCLAW_SRC_DIR" fetch --tags --prune
  git -C "$OPENCLAW_SRC_DIR" checkout main
  git -C "$OPENCLAW_SRC_DIR" pull --ff-only
else
  rm -rf "$OPENCLAW_SRC_DIR"
  git clone "$OPENCLAW_GIT_REPO" "$OPENCLAW_SRC_DIR"
fi

info "Building Docker image ($OPENCLAW_IMAGE)"
docker build \
  --build-arg "OPENCLAW_DOCKER_APT_PACKAGES=${OPENCLAW_DOCKER_APT_PACKAGES:-jq}" \
  -t "$OPENCLAW_IMAGE" \
  -f "$OPENCLAW_SRC_DIR/Dockerfile" \
  "$OPENCLAW_SRC_DIR"

info "Deploying config templates"
mkdir -p "$OPENCLAW_CONFIG_DIR"
for f in "$ROOT_DIR"/config/openclaw*.json; do
  [[ -f "$f" ]] || continue
  dest="$OPENCLAW_CONFIG_DIR/$(basename "$f")"
  if [[ ! -f "$dest" ]]; then
    cp "$f" "$dest"
    info "Wrote $dest"
  else
    info "$(basename "$f") already exists at $dest (leaving untouched)"
  fi
done
info "Note: existing config templates in $OPENCLAW_CONFIG_DIR are preserved; merge template changes into your deployed openclaw.json manually."

deploy_workspace_templates \
  "$ROOT_DIR" \
  "$OPENCLAW_WORKSPACES_DIR" \
  "$SYNC_WORKSPACES" \
  "$DRY_RUN" \
  "$CLEANUP_BOOTSTRAP"

# Ensure gateway.mode=local is set so the gateway starts without onboarding
DEPLOYED_CONFIG="$OPENCLAW_CONFIG_DIR/openclaw.json"
if [[ -f "$DEPLOYED_CONFIG" ]]; then
  python3 - "$DEPLOYED_CONFIG" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as f:
    cfg = json.load(f)
gw   = cfg.setdefault("gateway", {})
auth = gw.setdefault("auth", {})
ui   = gw.setdefault("controlUi", {})
changed = False
if gw.get("mode") != "local":
    gw["mode"] = "local"
    changed = True
if gw.get("bind") != "lan":
    gw["bind"] = "lan"
    changed = True
if auth.get("mode") != "token":
    auth["mode"] = "token"
    changed = True
if auth.get("token") != "${OPENCLAW_GATEWAY_TOKEN}":
    auth["token"] = "${OPENCLAW_GATEWAY_TOKEN}"
    changed = True
if ui.get("dangerouslyAllowHostHeaderOriginFallback") is not False:
    ui["dangerouslyAllowHostHeaderOriginFallback"] = False
    changed = True
allowed = ui.get("allowedOrigins")
required_origins = [
    "http://127.0.0.1:${OPENCLAW_GATEWAY_PORT}",
    "http://localhost:${OPENCLAW_GATEWAY_PORT}",
]
if not isinstance(allowed, list) or sorted(allowed) != sorted(required_origins):
    ui["allowedOrigins"] = required_origins
    changed = True
rate = auth.get("rateLimit")
required_rate = {
    "maxAttempts": 10,
    "windowMs": 60000,
    "lockoutMs": 300000,
}
if not isinstance(rate, dict) or rate != required_rate:
    auth["rateLimit"] = required_rate
    changed = True
if changed:
    with open(path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
    print("==> Patched gateway config in " + path)
PY
fi

info "Starting gateway"
compose up -d openclaw-gateway

info "Done."
info "Workspaces root: $OPENCLAW_WORKSPACES_DIR"
info "Default workspace: $OPENCLAW_WORKSPACE_DIR"
info "Config/state:    $OPENCLAW_CONFIG_DIR"
echo ""
echo "  Dashboard: http://127.0.0.1:${OPENCLAW_GATEWAY_PORT:-18789}/#token=${OPENCLAW_GATEWAY_TOKEN}"
echo ""
