#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

ensure_docker_running
load_env

info "Opening interactive shell in openclaw-cli container"
info "This will create an 'openclaw' helper inside the shell."
info "Type 'openclaw --help' to see available commands."
info "Use 'openclaw status' or 'openclaw dashboard' to talk to the running gateway (do not run 'openclaw gateway' here—that runs in another container via ./scripts/up.sh)."

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

