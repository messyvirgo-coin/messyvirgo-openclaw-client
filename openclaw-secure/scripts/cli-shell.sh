#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

ensure_docker_running
load_env

info "openclaw-cli: interactive shell (run: openclaw --help)"

# The service entrypoint is the OpenClaw CLI; override it to get a shell.
# Also add a helper so `openclaw ...` works (the CLI is `node /app/openclaw.mjs`).
compose run --rm --entrypoint bash openclaw-cli -lc '
cat > /tmp/openclawrc <<'"'"'EOF'"'"'
openclaw() {
  node /app/openclaw.mjs "$@"
}
EOF
exec bash --rcfile /tmp/openclawrc -i
'

