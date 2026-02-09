#!/usr/bin/env bash
# Install or update skills from https://github.com/BankrBot/openclaw-skills
# into the OpenClaw workspace (OPENCLAW_WORKSPACE_DIR/skills/).
# Run from repo root. Uses .env for OPENCLAW_WORKSPACE_DIR.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

require_cmd git

load_env

WORKSPACE="${OPENCLAW_WORKSPACE_DIR:-$HOME/OpenClawWorkspace}"
REPO_URL="https://github.com/BankrBot/openclaw-skills.git"
CACHE_DIR="$ROOT_DIR/.openclaw-skills-repo"

mkdir -p "$WORKSPACE/skills"

if [[ -d "$CACHE_DIR/.git" ]]; then
  info "Updating $REPO_URL in $CACHE_DIR"
  git -C "$CACHE_DIR" fetch --prune
  git -C "$CACHE_DIR" checkout main
  git -C "$CACHE_DIR" pull --ff-only
else
  info "Cloning $REPO_URL to $CACHE_DIR"
  rm -rf "$CACHE_DIR"
  git clone --depth 1 "$REPO_URL" "$CACHE_DIR"
fi

# Top-level dirs in the repo that contain SKILL.md (installable skills)
SKILL_DIRS=()
for d in "$CACHE_DIR"/*/; do
  [[ -d "$d" ]] || continue
  [[ -f "${d}SKILL.md" ]] || continue
  name="$(basename "$d")"
  SKILL_DIRS+=("$name")
done

for name in "${SKILL_DIRS[@]}"; do
  dst="$WORKSPACE/skills/$name"
  info "Installing skill: $name -> $dst"
  mkdir -p "$dst"
  rsync -a --delete "$CACHE_DIR/$name/" "$dst/" 2>/dev/null || cp -R "$CACHE_DIR/$name/"* "$dst/"
done

info "Done. Installed ${#SKILL_DIRS[@]} skills into $WORKSPACE/skills/"
info "Restart the gateway to pick up changes: ./scripts/down.sh && ./scripts/up.sh"
