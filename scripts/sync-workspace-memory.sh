#!/usr/bin/env bash
# Merge yesterday's and today's memory/YYYY-MM-DD.md into MEMORY.md so the agent gets
# long-term + yesterday + today at session start. On case-insensitive FS (e.g. macOS),
# MEMORY.md and memory.md are the same file. Run inside the gateway container (entrypoint).
set -eu
[[ -n "${BASH_VERSION:-}" ]] && set -o pipefail

WORKSPACE="${OPENCLAW_WORKSPACE_DIR:-/home/node/.openclaw/workspace}"
TODAY="$(date +%Y-%m-%d)"
if date -v-1d +%Y-%m-%d &>/dev/null; then
  YESTERDAY="$(date -v-1d +%Y-%m-%d)"
else
  YESTERDAY="$(date -d "yesterday" +%Y-%m-%d)"
fi
MEM="${WORKSPACE}/MEMORY.md"
TMP="${WORKSPACE}/.MEMORY.md.$$"

# Strip existing "## Yesterday (...)" and "## Today (...)" sections
strip_daily_sections() {
  awk '
    /^## (Yesterday|Today) \([0-9]{4}-[0-9]{2}-[0-9]{2}\)$/ { in_section = 1; next }
    in_section && /^## / { in_section = 0 }
    !in_section { print }
  ' "$1"
}

if [[ -f "$MEM" ]]; then
  strip_daily_sections "$MEM" > "$TMP"
else
  : > "$TMP"
fi

# Append Yesterday section if file exists
SRC_YESTERDAY="${WORKSPACE}/memory/${YESTERDAY}.md"
if [[ -f "$SRC_YESTERDAY" ]]; then
  printf '\n\n---\n\n## Yesterday (%s)\n\n' "$YESTERDAY" >> "$TMP"
  cat "$SRC_YESTERDAY" >> "$TMP"
fi

# Append Today section if file exists
SRC_TODAY="${WORKSPACE}/memory/${TODAY}.md"
if [[ -f "$SRC_TODAY" ]]; then
  printf '\n\n---\n\n## Today (%s)\n\n' "$TODAY" >> "$TMP"
  cat "$SRC_TODAY" >> "$TMP"
fi

if [[ -f "$SRC_YESTERDAY" ]] || [[ -f "$SRC_TODAY" ]]; then
  echo "sync-workspace-memory: merged long-term + yesterday (${YESTERDAY}) + today (${TODAY}) into MEMORY.md"
fi

# Ensure MEMORY.md always exists (e.g. for Moltbook scans); use minimal placeholder if empty
if [[ ! -s "$TMP" ]]; then
  printf '# Memory\n\n(Long-term and daily sections are merged here by the sync script.)\n' >> "$TMP"
fi
mv "$TMP" "$MEM"

exec "$@"
