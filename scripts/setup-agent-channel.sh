#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

CHANNEL="telegram"
AGENT_ID=""
TOKEN=""
TOKEN_FILE=""
USE_ENV=0
SKIP_AUDIT=0
NO_PROBE=0
TELEGRAM_USER_ID=""

usage() {
  cat <<'EOF'
Usage: ./scripts/setup-agent-channel.sh --agent <agent-id> [options]

Register a chat channel account and bind it to an existing agent.
Telegram is the default channel.

Options:
  --agent <id>         Agent ID to bind (required), e.g. messy-funds-mngr
  --channel <name>     Channel name for openclaw channels add (default: telegram)
  --token <token>      Channel token value (recommended for CI/non-interactive use)
  --token-file <path>  Path to file containing token (Telegram supports this)
  --use-env            Use env token resolution for default account (no inline token)
  --skip-audit         Skip running ./scripts/security-audit.sh before channel setup
  --no-probe           Skip post-setup channels status probe
  --telegram-user-id <id>  Add Telegram user ID to allowFrom/groupAllowFrom (recommended after pairing)
  -h, --help           Show this help

Examples:
  ./scripts/setup-agent-channel.sh --agent messy-funds-mngr
  ./scripts/setup-agent-channel.sh --agent messy-funds-mngr --token "$TELEGRAM_BOT_TOKEN"
  ./scripts/setup-agent-channel.sh --agent trader-2 --channel telegram --token-file .secrets/tg.token
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)
      AGENT_ID="${2:-}"
      shift 2
      ;;
    --channel)
      CHANNEL="${2:-}"
      shift 2
      ;;
    --token)
      TOKEN="${2:-}"
      shift 2
      ;;
    --token-file)
      TOKEN_FILE="${2:-}"
      shift 2
      ;;
    --use-env)
      USE_ENV=1
      shift
      ;;
    --skip-audit)
      SKIP_AUDIT=1
      shift
      ;;
    --no-probe)
      NO_PROBE=1
      shift
      ;;
    --telegram-user-id)
      TELEGRAM_USER_ID="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

[[ -n "$AGENT_ID" ]] || die "--agent is required (example: --agent messy-funds-mngr)"

if [[ -n "$TOKEN" && -n "$TOKEN_FILE" ]]; then
  die "Use only one of --token or --token-file."
fi
if [[ "$USE_ENV" == "1" && ( -n "$TOKEN" || -n "$TOKEN_FILE" ) ]]; then
  die "--use-env cannot be combined with --token or --token-file."
fi

ensure_docker_running

info "Checking gateway health"
if ! "$SCRIPT_DIR/cli.sh" health --json >/dev/null 2>&1; then
  die "Gateway is not reachable. Start OpenClaw first with ./scripts/up.sh"
fi

if [[ "$SKIP_AUDIT" != "1" ]]; then
  info "Running security audit before enabling external channel"
  "$SCRIPT_DIR/security-audit.sh"
fi

if [[ -z "$TOKEN" && -z "$TOKEN_FILE" && "$USE_ENV" != "1" ]]; then
  if [[ -t 0 ]]; then
    read -r -s -p "Enter $CHANNEL token: " TOKEN
    echo ""
    [[ -n "$TOKEN" ]] || die "Token cannot be empty."
  else
    die "Token input required in non-interactive mode; use --token, --token-file, or --use-env."
  fi
fi

info "Ensuring plugin '$CHANNEL' is enabled"
if ! "$SCRIPT_DIR/cli.sh" plugins enable "$CHANNEL"; then
  die "Failed to enable plugin '$CHANNEL'. Check available plugins with ./scripts/cli.sh plugins list"
fi

# Fail fast if the runtime still cannot resolve this channel (common when plugin schema is unavailable).
if ! "$SCRIPT_DIR/cli.sh" channels capabilities --channel "$CHANNEL" --json >/dev/null 2>&1; then
  die "Channel '$CHANNEL' schema is unavailable after plugin enable. Restart gateway: ./scripts/down.sh && ./scripts/up.sh"
fi

add_cmd=("$SCRIPT_DIR/cli.sh" channels add --channel "$CHANNEL")
if [[ -n "$TOKEN" ]]; then
  add_cmd+=(--token "$TOKEN")
elif [[ -n "$TOKEN_FILE" ]]; then
  add_cmd+=(--token-file "$TOKEN_FILE")
elif [[ "$USE_ENV" == "1" ]]; then
  add_cmd+=(--use-env)
fi

info "Registering $CHANNEL channel account"
"${add_cmd[@]}"

info "Binding '$CHANNEL' traffic to agent '$AGENT_ID'"
"$SCRIPT_DIR/cli.sh" agents bind --agent "$AGENT_ID" --bind "$CHANNEL"

if [[ -n "$TELEGRAM_USER_ID" && "$CHANNEL" == "telegram" ]]; then
  info "Adding Telegram user $TELEGRAM_USER_ID to allowlist (allowFrom + groupAllowFrom)"
  "$SCRIPT_DIR/cli.sh" config set "channels.telegram.allowFrom" "[\"$TELEGRAM_USER_ID\"]" --strict-json
  "$SCRIPT_DIR/cli.sh" config set "channels.telegram.groupAllowFrom" "[\"$TELEGRAM_USER_ID\"]" --strict-json
fi

if [[ "$NO_PROBE" != "1" ]]; then
  info "Probing channel status"
  "$SCRIPT_DIR/cli.sh" channels status --probe
fi

cat <<EOF

Done.

EOF

if [[ "$CHANNEL" == "telegram" ]]; then
  cat <<EOF
Next steps for Telegram (first-time DM pairing):
  1) DM your bot in Telegram: /start, then "hi"
  2) Approve pending pairing:
     ./scripts/cli.sh pairing list telegram
     ./scripts/cli.sh pairing approve telegram <CODE>
  3) Add your Telegram user ID to the allowlist (fixes Doctor warning):
     ./scripts/cli.sh config set channels.telegram.allowFrom '["<YOUR_ID>"]' --strict-json
     ./scripts/cli.sh config set channels.telegram.groupAllowFrom '["<YOUR_ID>"]' --strict-json
     ./scripts/down.sh && ./scripts/up.sh

   See docs/TELEGRAM-PERMISSIONS.md for all options and recommended settings.
EOF
fi

cat <<'EOF'

Quick verify:
  ./scripts/cli.sh agents bindings
EOF
