#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

TARGET_SRC_DIR="${1:-${OPENCLAW_SRC_DIR:-}}"
if [[ -z "$TARGET_SRC_DIR" ]]; then
  die "OPENCLAW_SRC_DIR is not set and no source dir argument was provided."
fi

TARGET_FILE="$TARGET_SRC_DIR/src/infra/install-package-dir.ts"
if [[ ! -f "$TARGET_FILE" ]]; then
  die "Expected source file not found: $TARGET_FILE"
fi

python3 - "$TARGET_FILE" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
needle = ', "--omit=peer"'
if needle not in text:
    print(f"==> OpenClaw source patch already applied in {path}")
    raise SystemExit(0)

updated = text.replace(needle, "", 1)
path.write_text(updated)
print(f"==> Patched OpenClaw source to keep peer deps during plugin install: {path}")
PY
