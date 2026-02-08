#!/usr/bin/env bash
# After you send a message to your Telegram bot, run this to see the pairing code and approve.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

ensure_docker_running
load_env

info "Send a message to your Telegram bot now (e.g. Hello or /start)."
info "Waiting 8 seconds, then listing pending pairing requests..."
sleep 8

info "Pending Telegram pairing requests:"
compose_base run --rm openclaw-cli pairing list telegram

echo ""
info "If you see a code above, approve it with:"
info "  ./scripts/cli.sh pairing approve telegram <CODE>"
info "Then send another message to the bot; it should reply."
