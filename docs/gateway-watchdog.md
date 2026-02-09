# OpenClaw Gateway Watchdog

The watchdog checks whether the OpenClaw gateway is responding and restarts it if not. It can run in the background and notify you (macOS notification and/or Telegram) when a restart happens.

## What it does

- **Check:** Every 60 seconds (configurable), the script requests `http://127.0.0.1:${OPENCLAW_GATEWAY_PORT:-18789}/`. If the request fails, it retries up to 2 times with a 5-second delay.
- **Restart:** If all retries fail, it runs `compose restart openclaw-gateway` (using the same compose stack as `./scripts/up.sh`).
- **Notify:** After a restart it sends:
  - A **macOS notification** (when run on macOS).
  - A **Telegram message** (optional), if `OPENCLAW_WATCHDOG_TELEGRAM_BOT_TOKEN` and `OPENCLAW_WATCHDOG_TELEGRAM_CHAT_ID` are set.
- **Log:** Events are appended to `scripts/logs/gateway-watchdog.log`.

## Configuration (optional)

Set these in your `.env` or in the LaunchAgent plist’s `EnvironmentVariables`:

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCLAW_WATCHDOG_INTERVAL` | 60 | Seconds between checks. |
| `OPENCLAW_WATCHDOG_CHECK_TIMEOUT` | 10 | Curl timeout in seconds. |
| `OPENCLAW_WATCHDOG_RETRIES` | 2 | Number of retries before declaring the gateway down. |
| `OPENCLAW_WATCHDOG_RETRY_DELAY` | 5 | Seconds between retries. |
| `OPENCLAW_WATCHDOG_TELEGRAM_BOT_TOKEN` | (none) | Telegram bot token for notifications. |
| `OPENCLAW_WATCHDOG_TELEGRAM_CHAT_ID` | (none) | Your Telegram chat ID (required for Telegram notifications). |

The script also uses `OPENCLAW_GATEWAY_PORT` from `.env` (or 18789) for the health check.

## Run once (foreground)

```bash
./scripts/gateway-watchdog.sh
```

## Run in background (simple, does not survive reboot)

```bash
nohup ./scripts/gateway-watchdog.sh >> scripts/logs/gateway-watchdog.log 2>&1 &
```

## Run as a LaunchAgent (recommended: survives reboot, starts at login)

1. **Copy and customize the plist**

   ```bash
   # Replace REPO_ROOT with the absolute path to this repo, e.g.:
   REPO_ROOT="/Users/franco/messyvirgo-openclaw-client-main"

   sed "s|REPO_ROOT|$REPO_ROOT|g" scripts/com.messyvirgo.openclaw-watchdog.plist \
     > ~/Library/LaunchAgents/com.messyvirgo.openclaw-watchdog.plist
   ```

2. **Load the agent**

   ```bash
   launchctl load ~/Library/LaunchAgents/com.messyvirgo.openclaw-watchdog.plist
   ```

3. **Unload (stop the watchdog)**

   ```bash
   launchctl unload ~/Library/LaunchAgents/com.messyvirgo.openclaw-watchdog.plist
   ```

4. **Check it’s running**

   ```bash
   launchctl list | grep openclaw-watchdog
   ```

The watchdog will start at login and keep running. Logs:

- `scripts/logs/gateway-watchdog.log` — script events (restarts, etc.)
- `scripts/logs/gateway-watchdog-stdout.log` — stdout from the process (usually empty)
- `scripts/logs/gateway-watchdog-stderr.log` — stderr from the process

## Telegram notifications

1. Get your Telegram **chat ID** (e.g. message your bot, then call `getUpdates` on the Bot API, or use a “user id” bot).
2. Add to `.env` (or to the plist’s `EnvironmentVariables` if using LaunchAgent):

   ```bash
   OPENCLAW_WATCHDOG_TELEGRAM_BOT_TOKEN=your_bot_token
   OPENCLAW_WATCHDOG_TELEGRAM_CHAT_ID=your_chat_id
   ```

   You can use the same bot token as in OpenClaw’s `channels.telegram.botToken` (in `openclaw.json`).

3. Restart the watchdog (or reload the LaunchAgent) so it picks up the new variables.
