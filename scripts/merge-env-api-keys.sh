#!/usr/bin/env bash
# Merge .env.api-keys into .env: for each KEY=value in .env.api-keys, if KEY is not
# already set in .env, append it. This ensures API keys survive setup.sh overwriting .env
# (e.g. after OpenClaw updates). Run from repo root; called by up.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
API_KEYS_FILE="$ROOT_DIR/.env.api-keys"

[[ -f "$API_KEYS_FILE" ]] || exit 0

# Keys already present in .env (simple KEY= at start of line)
existing_keys() {
  grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$ENV_FILE" 2>/dev/null | cut -d= -f1 || true
}

# Append lines from .env.api-keys whose key is not in .env
EXISTING="$(existing_keys)"
APPENDED=0
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="${line%"${line##*[![:space:]]}"}"
  [[ -z "$line" ]] && continue
  if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
    key="${BASH_REMATCH[1]}"
    if echo "$EXISTING" | grep -qFx "$key"; then
      continue
    fi
    echo "$line" >> "$ENV_FILE"
    EXISTING="$EXISTING"$'\n'"$key"
    ((APPENDED++)) || true
  fi
done < "$API_KEYS_FILE"

if [[ "${APPENDED:-0}" -gt 0 ]]; then
  echo "==> Merged ${APPENDED} key(s) from .env.api-keys into .env"
fi
