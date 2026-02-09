#!/usr/bin/env bash
# Install the x-api skill (X/Twitter monitoring via twitterapi.io) from
# https://github.com/shalomma/social-media-research into the OpenClaw workspace.
# Use for monitoring e.g. @MEssyVirgoCoin, @MessyVirgoBot, @MessyVirgoF, @MessyVirgoM.
# Run from repo root. Requires XAPI_IO_API_KEY from https://twitterapi.io
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

require_cmd git

load_env

WORKSPACE="${OPENCLAW_WORKSPACE_DIR:-$HOME/OpenClawWorkspace}"
REPO_URL="https://github.com/shalomma/social-media-research.git"
CACHE_DIR="$ROOT_DIR/.x-api-skill-repo"
SKILL_SRC="$CACHE_DIR/.claude/skills/x-api"
SKILL_DST="$WORKSPACE/skills/x-api"

mkdir -p "$WORKSPACE/skills"

if [[ -d "$CACHE_DIR/.git" ]]; then
  info "Updating $REPO_URL"
  git -C "$CACHE_DIR" fetch --prune
  git -C "$CACHE_DIR" checkout main
  git -C "$CACHE_DIR" pull --ff-only
else
  info "Cloning $REPO_URL"
  rm -rf "$CACHE_DIR"
  git clone --depth 1 "$REPO_URL" "$CACHE_DIR"
fi

if [[ ! -d "$SKILL_SRC" ]] || [[ ! -f "$SKILL_SRC/SKILL.md" ]]; then
  die "x-api skill not found at $SKILL_SRC"
fi

info "Installing skill: x-api -> $SKILL_DST"
mkdir -p "$SKILL_DST"
rsync -a --delete "$SKILL_SRC/" "$SKILL_DST/" 2>/dev/null || cp -R "$SKILL_SRC/"* "$SKILL_DST/"

info "Done. Set XAPI_IO_API_KEY (e.g. in openclaw.json skills.entries[\"x-api\"].env or container env)."
info "Restart the gateway to pick up the skill: ./scripts/down.sh && ./scripts/up.sh"
info "See docs/X-MONITORING-SKILLS.md for usage (e.g. search from:MEssyVirgoCoin)."
