#!/usr/bin/env bash
set -euo pipefail

# openclaw-raw scripts: native (non-Docker) OpenClaw with this repo's config
OPENCLAW_RAW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$OPENCLAW_RAW_ROOT/.." && pwd)"

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

load_env() {
  if [[ -f "$REPO_ROOT/.env" ]]; then
    # shellcheck disable=SC1091
    set -a && source "$REPO_ROOT/.env" && set +a
  fi
}

# Resolve OPENCLAW_SKILLS_DIR: empty → repo skills; relative → from repo root; absolute → as-is
resolve_openclaw_skills_dir() {
  local val="${1:-}"
  if [[ -z "$val" ]]; then
    echo "$REPO_ROOT/skills"
  elif [[ "$val" != /* ]]; then
    echo "$REPO_ROOT/$val"
  else
    echo "$val"
  fi
}

workspace_dir_for_agent() {
  local workspace_root="$1"
  local agent_id="$2"
  echo "$workspace_root/$agent_id"
}

deploy_workspace_templates() {
  local repo_root="$1"
  local workspace_root="$2"
  local sync_workspaces="${3:-0}"
  local dry_run="${4:-0}"
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
        local backup_path="$dest.bak.$ts"
        if [[ "$dry_run" == "1" ]]; then
          info "[dry-run] would backup and overwrite $dest"
        else
          cp "$dest" "$backup_path"
          cp "$f" "$dest"
          info "Updated $dest (backup: $backup_path)"
        fi
      else
        info "$file_name already exists at $target_dir (leaving untouched)"
      fi
    done
  done
}
