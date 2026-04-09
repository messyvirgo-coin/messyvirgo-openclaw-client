#!/usr/bin/env bash
set -euo pipefail

# Interactive bootstrap for Linux + macOS (Docker Desktop)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

require_cmd git

ENV_FILE="$REPO_ROOT/.env"
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
      cat <<EOF
Usage: $0 [options]

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

is_managed_env_key() {
  local candidate="$1"
  shift
  local key
  for key in "$@"; do
    if [[ "$key" == "$candidate" ]]; then
      return 0
    fi
  done
  return 1
}

ensure_docker_running

info "Preparing .env"
if [[ ! -f "$ENV_FILE" ]]; then
  if [[ -f "$REPO_ROOT/.env.secure.example" ]]; then
    cp "$REPO_ROOT/.env.secure.example" "$ENV_FILE"
  else
    die "Missing .env.secure.example (repo incomplete)."
  fi
fi

# Load current values (if any) so we can prompt with them
load_env

DEFAULT_CONFIG_DIR="$(openclaw_host_config_dir)"
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
  DEFAULT_WORKSPACES_DIR="$DEFAULT_CONFIG_DIR/workspaces"
fi
DEFAULT_SRC_DIR="$(openclaw_host_src_dir)"
DEFAULT_GIT_REPO="${OPENCLAW_GIT_REPO:-https://github.com/openclaw/openclaw}"
DEFAULT_IMAGE="${OPENCLAW_IMAGE:-openclaw-secure:local}"
DEFAULT_NPM_VERSION="${OPENCLAW_NPM_VERSION:-11.11.1}"

if [[ "$INTERACTIVE" == "1" ]]; then
  OPENCLAW_CONFIG_DIR="$(prompt_default "Host config/state directory" "$DEFAULT_CONFIG_DIR")"
  OPENCLAW_WORKSPACES_DIR="$(prompt_default "Host root directory for per-agent workspaces" "$DEFAULT_WORKSPACES_DIR")"
  OPENCLAW_SRC_DIR="$(prompt_default "Where to clone OpenClaw source (for building)" "$(openclaw_host_src_dir)")"
  OPENCLAW_GIT_REPO="$(prompt_default "OpenClaw Git repo URL to clone/pull" "$DEFAULT_GIT_REPO")"
  OPENCLAW_IMAGE="$(prompt_default "Docker image tag to build" "$DEFAULT_IMAGE")"
else
  OPENCLAW_CONFIG_DIR="$DEFAULT_CONFIG_DIR"
  OPENCLAW_WORKSPACES_DIR="$DEFAULT_WORKSPACES_DIR"
  OPENCLAW_SRC_DIR="$DEFAULT_SRC_DIR"
  OPENCLAW_GIT_REPO="$DEFAULT_GIT_REPO"
  OPENCLAW_IMAGE="$DEFAULT_IMAGE"
fi
OPENCLAW_NPM_VERSION="${OPENCLAW_NPM_VERSION:-$DEFAULT_NPM_VERSION}"
if [[ "$OPENCLAW_WORKSPACES_DIR" == "$HOME" || "$OPENCLAW_WORKSPACES_DIR" == "/" ]]; then
  die "Refusing unsafe workspaces root '$OPENCLAW_WORKSPACES_DIR'. Use a dedicated subdirectory (for example $DEFAULT_CONFIG_DIR/workspaces)."
fi
OPENCLAW_WORKSPACE_DIR="$OPENCLAW_WORKSPACES_DIR/main"

OPENCLAW_DEFAULT_CONFIG_DIR="$HOME/.openclaw"
WRITE_OPENCLAW_CONFIG_TO_ENV=0
if [[ "$OPENCLAW_CONFIG_DIR" != "$OPENCLAW_DEFAULT_CONFIG_DIR" ]]; then
  WRITE_OPENCLAW_CONFIG_TO_ENV=1
fi

OPENCLAW_DEFAULT_SRC_DIR="${OPENCLAW_CONFIG_DIR}/openclaw-src"
WRITE_OPENCLAW_SRC_TO_ENV=0
if [[ "$OPENCLAW_SRC_DIR" != "$OPENCLAW_DEFAULT_SRC_DIR" ]]; then
  WRITE_OPENCLAW_SRC_TO_ENV=1
fi

ensure_host_dir_writable "$OPENCLAW_CONFIG_DIR" "config/state directory" 1
chmod 700 "$OPENCLAW_CONFIG_DIR"
ensure_host_dir_writable "$OPENCLAW_WORKSPACES_DIR" "workspaces root directory" 1
ensure_host_dir_writable "$OPENCLAW_WORKSPACE_DIR" "default workspace directory" 1
ensure_host_dir_writable "$(dirname "$OPENCLAW_SRC_DIR")" "OpenClaw source parent directory" 1

if [[ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]]; then
  OPENCLAW_GATEWAY_TOKEN="$(random_hex_64)"
fi

managed_env_keys=(
  OPENROUTER_API_KEY
  BRAVE_API_KEY
  OPENCLAW_WORKSPACES_DIR
  OPENCLAW_WORKSPACE_DIR
  OPENCLAW_GATEWAY_PORT
  OPENCLAW_BRIDGE_PORT
  OPENCLAW_GATEWAY_BIND
  OPENCLAW_IMAGE
  OPENCLAW_GATEWAY_TOKEN
  OPENCLAW_DOCKER_APT_PACKAGES
  OPENCLAW_GIT_REPO
  OPENCLAW_NPM_VERSION
)

preserved_env_lines=()
if [[ -f "$ENV_FILE" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)= ]]; then
      env_key="${BASH_REMATCH[1]}"
      if [[ "$env_key" == "OPENCLAW_CONFIG_DIR" || "$env_key" == "OPENCLAW_SRC_DIR" ]]; then
        continue
      fi
      if ! is_managed_env_key "$env_key" "${managed_env_keys[@]}"; then
        preserved_env_lines+=("$line")
      fi
    fi
  done <"$ENV_FILE"
fi

# Write .env (simple overwrite, deterministic keys)
cat >"$ENV_FILE" <<EOF
OPENROUTER_API_KEY=${OPENROUTER_API_KEY:-}
BRAVE_API_KEY=${BRAVE_API_KEY:-}
OPENCLAW_WORKSPACES_DIR=$OPENCLAW_WORKSPACES_DIR
OPENCLAW_WORKSPACE_DIR=$OPENCLAW_WORKSPACE_DIR
OPENCLAW_GATEWAY_PORT=${OPENCLAW_GATEWAY_PORT:-18789}
OPENCLAW_BRIDGE_PORT=${OPENCLAW_BRIDGE_PORT:-18790}
OPENCLAW_GATEWAY_BIND=${OPENCLAW_GATEWAY_BIND:-lan}
OPENCLAW_IMAGE=$OPENCLAW_IMAGE
OPENCLAW_GATEWAY_TOKEN=$OPENCLAW_GATEWAY_TOKEN
OPENCLAW_DOCKER_APT_PACKAGES=${OPENCLAW_DOCKER_APT_PACKAGES:-jq}
OPENCLAW_GIT_REPO=$OPENCLAW_GIT_REPO
OPENCLAW_NPM_VERSION=$OPENCLAW_NPM_VERSION
EOF
if [[ "$WRITE_OPENCLAW_CONFIG_TO_ENV" == "1" ]]; then
  echo "OPENCLAW_CONFIG_DIR=$OPENCLAW_CONFIG_DIR" >>"$ENV_FILE"
fi
if [[ "$WRITE_OPENCLAW_SRC_TO_ENV" == "1" ]]; then
  echo "OPENCLAW_SRC_DIR=$OPENCLAW_SRC_DIR" >>"$ENV_FILE"
fi

if [[ "${#preserved_env_lines[@]}" -gt 0 ]]; then
  {
    printf "\n# Preserved custom keys from previous .env\n"
    printf "%s\n" "${preserved_env_lines[@]}"
  } >>"$ENV_FILE"
fi

# shellcheck disable=SC1090,SC1091
set -a && source "$ENV_FILE" && set +a
OPENCLAW_CONFIG_DIR="$(openclaw_host_config_dir)"
OPENCLAW_SRC_DIR="$(openclaw_host_src_dir)"

info "Cloning/updating OpenClaw source"
if [[ ! -d "$OPENCLAW_SRC_DIR/.git" ]]; then
  rm -rf "$OPENCLAW_SRC_DIR"
  git clone "$OPENCLAW_GIT_REPO" "$OPENCLAW_SRC_DIR"
fi
openclaw_sync_and_checkout_openclaw_source "$OPENCLAW_SRC_DIR" "$OPENCLAW_GIT_REPO"

info "Applying wrapper source patches"
"$SCRIPT_DIR/patch-openclaw-source.sh" "$OPENCLAW_SRC_DIR"

refresh_openclaw_pnpm_lockfile "$OPENCLAW_SRC_DIR"

info "Building Docker image ($OPENCLAW_IMAGE)"
OPENCLAW_DOCKER_BUILD_EXTRA_ARGS=()
if [[ -n "${OPENCLAW_NODE_BOOKWORM_IMAGE:-}" ]]; then
  OPENCLAW_DOCKER_BUILD_EXTRA_ARGS+=(--build-arg "OPENCLAW_NODE_BOOKWORM_IMAGE=$OPENCLAW_NODE_BOOKWORM_IMAGE")
  info "OpenClaw Dockerfile base: OPENCLAW_NODE_BOOKWORM_IMAGE=$OPENCLAW_NODE_BOOKWORM_IMAGE"
fi
if [[ ${#OPENCLAW_DOCKER_BUILD_EXTRA_ARGS[@]} -gt 0 ]]; then
  docker build \
    --build-arg "OPENCLAW_DOCKER_APT_PACKAGES=${OPENCLAW_DOCKER_APT_PACKAGES:-jq}" \
    "${OPENCLAW_DOCKER_BUILD_EXTRA_ARGS[@]}" \
    -t "$OPENCLAW_IMAGE" \
    -f "$OPENCLAW_SRC_DIR/Dockerfile" \
    "$OPENCLAW_SRC_DIR"
else
  docker build \
    --build-arg "OPENCLAW_DOCKER_APT_PACKAGES=${OPENCLAW_DOCKER_APT_PACKAGES:-jq}" \
    -t "$OPENCLAW_IMAGE" \
    -f "$OPENCLAW_SRC_DIR/Dockerfile" \
    "$OPENCLAW_SRC_DIR"
fi

info "Pinning npm and installing @messyvirgo/cli in runtime image (${MESSYVIRGO_CLI_VERSION:-latest})"
docker build \
  --build-arg "BASE_IMAGE=$OPENCLAW_IMAGE" \
  --build-arg "OPENCLAW_NPM_VERSION=$OPENCLAW_NPM_VERSION" \
  --build-arg "MESSYVIRGO_CLI_VERSION=${MESSYVIRGO_CLI_VERSION:-latest}" \
  -t "$OPENCLAW_IMAGE" \
  -f "$OPENCLAW_SECURE_ROOT/docker/npm-overlay.Dockerfile" \
  "$REPO_ROOT"

info "Deploying config templates"
mkdir -p "$OPENCLAW_CONFIG_DIR"
# Deploy Docker baseline config (compose mounts host ~/.openclaw into the container).
f="$REPO_ROOT/config/openclaw.json"
if [[ -f "$f" ]]; then
  dest="$OPENCLAW_CONFIG_DIR/$(basename "$f")"
  if [[ ! -f "$dest" ]]; then
    cp "$f" "$dest"
    info "Wrote $dest"
  else
    info "$(basename "$f") already exists at $dest (leaving untouched)"
    info "Existing config in $OPENCLAW_CONFIG_DIR left unchanged; merge template updates manually if needed."
  fi
fi

deploy_workspace_templates \
  "$REPO_ROOT" \
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
# Gateway container has no Docker CLI/socket; tool sandboxing cannot spawn nested containers.
agents = cfg.setdefault("agents", {})
defaults = agents.setdefault("defaults", {})
sb = defaults.setdefault("sandbox", {})
if sb.get("mode") != "off":
    sb["mode"] = "off"
    changed = True
if changed:
    with open(path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
    print("==> Patched gateway/sandbox config in " + path)
PY
fi

info "Starting gateway"
compose up -d openclaw-gateway

info "Setup complete."
printf 'Workspaces: %s\nDefault:      %s\nConfig:       %s\nDashboard:    http://127.0.0.1:%s/#token=%s\n' \
  "$OPENCLAW_WORKSPACES_DIR" "$OPENCLAW_WORKSPACE_DIR" "$OPENCLAW_CONFIG_DIR" \
  "${OPENCLAW_GATEWAY_PORT:-18789}" "$OPENCLAW_GATEWAY_TOKEN"
echo ""
