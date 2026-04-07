# Telegram Setup

This guide covers the steps to create a Telegram bot, register it with OpenClaw, and pair it with an agent. Use the `openclaw-secure` commands for Docker and the `openclaw-raw` commands for native.

## Create A Bot

1. Open Telegram and start a chat with `@BotFather`.
2. Send `/newbot`.
3. Choose a bot name and a username ending in `bot`.
4. Copy the token BotFather returns and store it securely.

Do not commit real bot tokens. Put them in `.env` or paste them only when the CLI prompts for them.

## Prerequisites

- The gateway is running.
- You know which agent to bind the channel to.
- If you use Messy Virgo MCP tools, set `MESSY_VIRGO_API_KEY` and `MESSY_VIRGO_MCP_URL` in `.env`.

The wrapper defaults Telegram to the `main` account, so the usual path is to register the bot under `main` and bind it to the `main` agent.

## Register The Channel

```bash
# Docker
./openclaw-secure/scripts/cli.sh channels add --channel telegram --account main --name "Messy Virgo" --token "<telegram_bot_token>"
./openclaw-secure/scripts/cli.sh agents bind --agent main --bind telegram:main

# Native
./openclaw-raw/scripts/cli.sh channels add --channel telegram --account main --name "Messy Virgo" --token "<telegram_bot_token>"
./openclaw-raw/scripts/cli.sh agents bind --agent main --bind telegram:main
```

If you are setting up a second bot, change `--account` and bind that account to the target agent.

## Set Group Policy

Use `allowlist` for group chats unless you explicitly want an open trusted group. Telegram group allowlists use numeric Telegram user IDs.

```bash
# Docker
./openclaw-secure/scripts/cli.sh config set channels.telegram.groupPolicy '"allowlist"'
./openclaw-secure/scripts/cli.sh config set channels.telegram.accounts.main.groupPolicy '"allowlist"'
./openclaw-secure/scripts/cli.sh config set channels.telegram.accounts.main.groupAllowFrom '["tg:<telegram_user_id>"]'

# Native
./openclaw-raw/scripts/cli.sh config set channels.telegram.groupPolicy '"allowlist"'
./openclaw-raw/scripts/cli.sh config set channels.telegram.accounts.main.groupPolicy '"allowlist"'
./openclaw-raw/scripts/cli.sh config set channels.telegram.accounts.main.groupAllowFrom '["tg:<telegram_user_id>"]'
```

Replace `<telegram_user_id>` with the numeric Telegram user ID you want to allow.

## Restart And Verify

```bash
# Docker
./openclaw-secure/scripts/down.sh
./openclaw-secure/scripts/up.sh
./openclaw-secure/scripts/cli.sh channels list
./openclaw-secure/scripts/cli.sh agents list --bindings

# Native
./openclaw-raw/scripts/gateway.sh
./openclaw-raw/scripts/cli.sh channels list
./openclaw-raw/scripts/cli.sh agents list --bindings
```

## Pair The Bot

The first message usually triggers a pairing code. Approve it with:

```bash
# Docker
./openclaw-secure/scripts/cli.sh pairing approve telegram <pairing_code>

# Native
./openclaw-raw/scripts/cli.sh pairing approve telegram <pairing_code>
```

If the bot does not prompt immediately, send a simple message like `Hi` and try again.
