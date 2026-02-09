#!/usr/bin/env bash
#
# OpenClaw Gateway Watchdog
# Checks if the gateway HTTP endpoint responds; restarts the gateway container
# if not, then sends a notification (macOS notification + optional Telegram).
# Run in the background or via LaunchAgent (see docs/gateway-watchdog.md).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/_common.sh"

LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/gateway-watchdog.log"
INTERVAL="${OPENCLAW_WATCHDOG_INTERVAL:-60}"
CHECK_TIMEOUT="${OPENCLAW_WATCHDOG_CHECK_TIMEOUT:-10}"
RETRIES="${OPENCLAW_WATCHDOG_RETRIES:-2}"
RETRY_DELAY="${OPENCLAW_WATCHDOG_RETRY_DELAY:-5}"

mkdir -p "$LOG_DIR"

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" >> "$LOG_FILE"
}

# Returns 0 if gateway is responding
check_gateway() {
  load_env
  local port="${OPENCLAW_GATEWAY_PORT:-18789}"
  curl -sf -o /dev/null --connect-timeout 5 --max-time "$CHECK_TIMEOUT" \
    "http://127.0.0.1:${port}/" 2>/dev/null
}

restart_gateway() {
  load_env
  ensure_docker_running
  compose restart openclaw-gateway
}

notify_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    return 0
  fi
  osascript -e "display notification \"OpenClaw gateway was down and has been restarted.\" with title \"OpenClaw Watchdog\"" 2>/dev/null || true
}

notify_telegram() {
  local bot_token="${OPENCLAW_WATCHDOG_TELEGRAM_BOT_TOKEN:-}"
  local chat_id="${OPENCLAW_WATCHDOG_TELEGRAM_CHAT_ID:-}"
  if [[ -z "$bot_token" || -z "$chat_id" ]]; then
    return 0
  fi
  local text="OpenClaw gateway was down and has been restarted."
  curl -sf -o /dev/null "https://api.telegram.org/bot${bot_token}/sendMessage" \
    --data-urlencode "chat_id=$chat_id" \
    --data-urlencode "text=$text" \
    --max-time 10 2>/dev/null || true
}

notify() {
  notify_macos
  notify_telegram
}

# Optional: load .env so Telegram vars are available in the loop
load_env 2>/dev/null || true

log "Watchdog started (interval=${INTERVAL}s, retries=${RETRIES})"

while true; do
  failed=0
  for (( i=0; i < RETRIES; i++ )); do
    if check_gateway; then
      failed=0
      break
    fi
    failed=1
    [[ $i -lt $((RETRIES - 1)) ]] && sleep "$RETRY_DELAY"
  done

  if [[ "$failed" -eq 1 ]]; then
    log "Gateway not responding; restarting..."
    if restart_gateway >> "$LOG_FILE" 2>&1; then
      log "Gateway restarted successfully"
      notify
    else
      log "Gateway restart failed"
    fi
  fi

  sleep "$INTERVAL"
done
