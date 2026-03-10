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
    -f "$ROOT_DIR/docker-compose.skills.yml" \
    "$@"
}

compose_linux_hostnet() {
  docker compose \
    -f "$ROOT_DIR/docker-compose.yml" \
    -f "$ROOT_DIR/docker-compose.secure.yml" \
    -f "$ROOT_DIR/docker-compose.linux-hostnet.yml" \
    -f "$ROOT_DIR/docker-compose.skills.yml" \
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
  # Linux: use host networking (avoids Docker bridge NAT issues with device pairing).
  # macOS: use bridge networking with localhost port mapping (Docker Desktop requirement).
  if ! is_macos && [[ -f "$ROOT_DIR/docker-compose.linux-hostnet.yml" ]]; then
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

ensure_openclaw_runtime_config() {
  local config_dir="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw-secure}"
  local openclaw_path="$config_dir/openclaw.json"
  [[ -f "$openclaw_path" ]] || return 0

  python3 - "$openclaw_path" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path) as f:
    cfg = json.load(f)

changed = False
agents = cfg.get("agents", {}).get("list", [])
target = None
for agent in agents:
    if isinstance(agent, dict) and agent.get("id") == "messy-funds-mngr":
        target = agent
        break

if isinstance(target, dict):
    tools = target.get("tools")
    if not isinstance(tools, dict):
        tools = {}
        target["tools"] = tools
        changed = True

    allow = tools.get("allow")
    if not isinstance(allow, list):
        allow = []
        tools["allow"] = allow
        changed = True

    required_allow = [
        "read",
        "write",
        "edit",
        "apply_patch",
        "exec",
        "process",
        "browser",
        "cron",
        "session_status",
        "sessions_list",
        "sessions_history",
        "sessions_send",
        "sessions_spawn",
        "web_search",
        "web_fetch",
        "memory_search",
        "memory_get",
    ]
    for item in required_allow:
        if item not in allow:
            allow.append(item)
            changed = True

    deny = tools.get("deny")
    if not isinstance(deny, list):
        deny = []
        tools["deny"] = deny
        changed = True

    required_deny = ["bash", "canvas", "gateway", "image", "message", "nodes"]
    for item in required_deny:
        if item not in deny:
            deny.append(item)
            changed = True

if changed:
    with open(path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
PY
}

render_mcporter_config() {
  local config_dir="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw-secure}"
  local mcporter_path="$config_dir/mcporter.json"
  [[ -f "$mcporter_path" ]] || return 0

  python3 - "$mcporter_path" "${MESSY_VIRGO_MCP_URL:-}" <<'PY'
import json
import sys
from urllib.parse import urlsplit, urlunsplit

path = sys.argv[1]
url = sys.argv[2]

def normalize_host_url(raw: str) -> str:
    if not raw:
        return raw
    try:
        parts = urlsplit(raw)
    except Exception:
        return raw

    if parts.hostname in {"localhost", "127.0.0.1", "::1"}:
        port = f":{parts.port}" if parts.port else ""
        netloc = f"host.docker.internal{port}"
        return urlunsplit((parts.scheme, netloc, parts.path, parts.query, parts.fragment))
    return raw

resolved_url = normalize_host_url(url)

with open(path) as f:
    cfg = json.load(f)

changed = False
servers = cfg.get("mcpServers", {})
for server_name, server in servers.items():
    base = server.get("baseUrl")
    if isinstance(base, str) and "${MESSY_VIRGO_MCP_URL}" in base:
        # Keep the template intact when URL is unset so a later run can still
        # materialize a real value from env.
        if resolved_url:
            server["baseUrl"] = resolved_url
            changed = True
    elif isinstance(base, str):
        normalized = normalize_host_url(base)
        if normalized != base:
            server["baseUrl"] = normalized
            changed = True
        # Recover from older runs that replaced the template with "".
        elif (
            not base
            and resolved_url
            and server_name == "messy-virgo-funds"
        ):
            server["baseUrl"] = resolved_url
            changed = True

    # Normalize legacy auth style to explicit header auth that mcporter
    # understands consistently across versions.
    token_env = server.get("bearerTokenEnv")
    if isinstance(token_env, str) and token_env:
        headers = server.get("headers")
        if not isinstance(headers, dict):
            headers = {}
        auth_header = f"Bearer ${{{token_env}}}"
        if headers.get("Authorization") != auth_header:
            headers["Authorization"] = auth_header
            server["headers"] = headers
            changed = True
        server.pop("bearerTokenEnv", None)
        changed = True

    headers = server.get("headers")
    if isinstance(headers, dict):
        auth_value = headers.get("Authorization")
        if isinstance(auth_value, str) and "$env:MESSY_VIRGO_API_KEY" in auth_value:
            headers["Authorization"] = auth_value.replace(
                "$env:MESSY_VIRGO_API_KEY", "${MESSY_VIRGO_API_KEY}"
            )
            server["headers"] = headers
            changed = True

if changed:
    with open(path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
PY
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

workspace_dir_for_agent() {
  local workspace_root="$1"
  local agent_id="$2"
  echo "$workspace_root/$agent_id"
}

sync_directory_contents() {
  local source_dir="$1"
  local target_dir="$2"
  local sync_mode="${3:-0}"
  local dry_run="${4:-0}"
  local ts="$5"
  local label="${6:-assets}"

  [[ -d "$source_dir" ]] || return 0

  if [[ "$dry_run" == "1" ]]; then
    info "[dry-run] would ensure $label dir: $target_dir"
  else
    mkdir -p "$target_dir"
  fi

  local src
  for src in "$source_dir"/*; do
    [[ -e "$src" ]] || continue
    local name dest
    name="$(basename "$src")"
    dest="$target_dir/$name"

    if [[ ! -e "$dest" ]]; then
      if [[ "$dry_run" == "1" ]]; then
        info "[dry-run] would create $dest"
      else
        cp -R "$src" "$dest"
        info "Wrote $dest"
      fi
      continue
    fi

    if cmp -s "$src" "$dest" 2>/dev/null; then
      info "$label item already up to date at $dest"
      continue
    fi

    if [[ "$sync_mode" == "1" ]]; then
      local backup_path
      backup_path="$dest.bak.$ts"
      if [[ "$dry_run" == "1" ]]; then
        info "[dry-run] would backup $dest -> $backup_path"
        info "[dry-run] would overwrite $dest from $source_dir"
      else
        cp -R "$dest" "$backup_path"
        rm -rf "$dest"
        cp -R "$src" "$dest"
        info "Updated $dest (backup: $backup_path)"
      fi
    else
      info "$dest already exists (leaving untouched)"
    fi
  done
}

deploy_workspace_templates() {
  local repo_root="$1"
  local workspace_root="$2"
  local sync_workspaces="${3:-0}"
  local dry_run="${4:-0}"
  local cleanup_bootstrap="${5:-0}"
  local ts
  ts="$(date +%Y%m%d-%H%M%S)"

  info "Deploying workspace templates"
  for agent_dir in "$repo_root"/config/workspaces/*/; do
    [[ -d "$agent_dir" ]] || continue
    local agent_id target_dir
    agent_id="$(basename "$agent_dir")"
    target_dir="$(workspace_dir_for_agent "$workspace_root" "$agent_id")"

    if [[ "$dry_run" == "1" ]]; then
      info "[dry-run] would ensure workspace dir: $target_dir"
    else
      mkdir -p "$target_dir"
    fi

    for f in "$agent_dir"*.md; do
      [[ -f "$f" ]] || continue
      local dest file_name
      file_name="$(basename "$f")"
      dest="$target_dir/$file_name"

      if [[ ! -f "$dest" ]]; then
        if [[ "$dry_run" == "1" ]]; then
          info "[dry-run] would create $dest"
        else
          cp "$f" "$dest"
          info "Wrote $dest"
        fi
        continue
      fi

      if cmp -s "$f" "$dest"; then
        info "$file_name already up to date at $target_dir"
        continue
      fi

      if [[ "$sync_workspaces" == "1" ]]; then
        local backup_path
        backup_path="$dest.bak.$ts"
        if [[ "$dry_run" == "1" ]]; then
          info "[dry-run] would backup $dest -> $backup_path"
          info "[dry-run] would overwrite $dest from template"
        else
          cp "$dest" "$backup_path"
          cp "$f" "$dest"
          info "Updated $dest (backup: $backup_path)"
        fi
      else
        info "$file_name already exists at $target_dir (leaving untouched)"
      fi
    done

    if [[ "$cleanup_bootstrap" == "1" ]]; then
      local bootstrap_path
      bootstrap_path="$target_dir/BOOTSTRAP.md"
      if [[ -f "$bootstrap_path" ]]; then
        local bootstrap_backup
        bootstrap_backup="$bootstrap_path.bak.$ts"
        if [[ "$dry_run" == "1" ]]; then
          info "[dry-run] would backup and remove $bootstrap_path"
        else
          cp "$bootstrap_path" "$bootstrap_backup"
          rm -f "$bootstrap_path"
          info "Removed $bootstrap_path (backup: $bootstrap_backup)"
        fi
      fi
    fi

    # Optional per-agent avatar assets.
    # Source: assets/avatars/<agent-id>/...
    # Target: <workspace>/<agent-id>/avatars/...
    sync_directory_contents \
      "$repo_root/assets/avatars/$agent_id" \
      "$target_dir/avatars" \
      "$sync_workspaces" \
      "$dry_run" \
      "$ts" \
      "avatar ($agent_id)"
  done
}
