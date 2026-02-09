#!/usr/bin/env bash
# Merge today's memory/YYYY-MM-DD.md into MEMORY.md so the agent gets both long-term and
# today's content at session start. On case-insensitive FS (e.g. macOS), MEMORY.md and
# memory.md are the same file, so we update MEMORY.md in place: keep long-term content,
# replace only the "## Today (YYYY-MM-DD)" section with today's file (or remove it if missing).
# Run inside the gateway container before starting the gateway (entrypoint).

set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE_DIR:-/home/node/.openclaw/workspace}"
TODAY="$(date +%Y-%m-%d)"
SRC="${WORKSPACE}/memory/${TODAY}.md"
MEM="${WORKSPACE}/MEMORY.md"
TMP="${WORKSPACE}/.MEMORY.md.$$"

# Strip existing "## Today (YYYY-MM-DD)" section from MEMORY.md (from that header to end or next ##)
strip_today_section() {
  awk '
    /^## Today \([0-9]{4}-[0-9]{2}-[0-9]{2}\)$/ { in_today = 1; next }
    in_today && /^## / { in_today = 0 }
    !in_today { print }
  ' "$1"
}

if [[ -f "$MEM" ]]; then
  strip_today_section "$MEM" > "$TMP"
else
  : > "$TMP"
fi

if [[ -f "$SRC" ]]; then
  printf '\n\n---\n\n## Today (%s)\n\n' "$TODAY" >> "$TMP"
  cat "$SRC" >> "$TMP"
  echo "sync-workspace-memory: merged memory/${TODAY}.md into MEMORY.md (long-term + today)"
else
  echo "sync-workspace-memory: no memory/${TODAY}.md; kept MEMORY.md without today's section"
fi

mv "$TMP" "$MEM"

exec "$@"
