#!/usr/bin/env bash
# Merge .env.api-keys into .env: for each KEY=value in .env.api-keys, set that in .env
# (overwriting any existing value for KEY). This makes .env.api-keys the source of truth
# so key updates there take effect on the next up.sh. Run from repo root; called by up.sh.
set -eu
[[ -n "${BASH_VERSION:-}" ]] && set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
API_KEYS_FILE="$ROOT_DIR/.env.api-keys"

[[ -f "$API_KEYS_FILE" ]] || exit 0

# Collect keys defined in .env.api-keys (so we can strip them from .env)
API_KEYS_NAMES=""
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="${line%"${line##*[![:space:]]}"}"
  [[ -z "$line" ]] && continue
  if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)= ]]; then
    API_KEYS_NAMES="$API_KEYS_NAMES${BASH_REMATCH[1]}"$'\n'
  fi
done < "$API_KEYS_FILE"

# Remove from .env any line whose key is in .env.api-keys (so we overwrite with fresh values)
if [[ -f "$ENV_FILE" ]]; then
  TMP="$ENV_FILE.$$"
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)= ]]; then
      key="${BASH_REMATCH[1]}"
      echo "$API_KEYS_NAMES" | grep -qFx "$key" && continue
    fi
    printf '%s\n' "$line" >> "$TMP"
  done < "$ENV_FILE"
  mv "$TMP" "$ENV_FILE"
fi

# Append all KEY=value lines from .env.api-keys
UPDATED=0
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="${line%"${line##*[![:space:]]}"}"
  [[ -z "$line" ]] && continue
  if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
    echo "$line" >> "$ENV_FILE"
    ((UPDATED++)) || true
  fi
done < "$API_KEYS_FILE"

if [[ "${UPDATED:-0}" -gt 0 ]]; then
  echo "==> Merged ${UPDATED} key(s) from .env.api-keys into .env"
fi
