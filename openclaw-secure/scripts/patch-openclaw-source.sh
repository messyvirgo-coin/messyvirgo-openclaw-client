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

# Upstream occasionally ships extensions/acpx/package.json with @agentclientprotocol/sdk@^0.9.4,
# which has no matching release on the public npm registry (ERR_PNPM_NO_MATCHING_VERSION).
ACPX_PKG="$TARGET_SRC_DIR/extensions/acpx/package.json"
if [[ -f "$ACPX_PKG" ]]; then
  python3 - "$ACPX_PKG" <<'PY'
import json, pathlib, sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
deps = data.get("dependencies")
if not isinstance(deps, dict):
    raise SystemExit(0)
key = "@agentclientprotocol/sdk"
if key not in deps:
    raise SystemExit(0)
ver = deps[key]
# Broken range(s) seen on openclaw main; registry publishes 0.18.x as current line.
broken = ("^0.9.4", "~0.9.4", "0.9.4")
if ver in broken or (isinstance(ver, str) and ver.startswith("^0.9.")):
    deps[key] = "^0.18.0"
    path.write_text(json.dumps(data, indent=2) + "\n")
    print(f"==> Patched {key} to ^0.18.0 in {path} (wrapper workaround for missing npm versions)")
PY
fi
