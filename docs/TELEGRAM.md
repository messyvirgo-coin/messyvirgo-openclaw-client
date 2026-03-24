# Telegram bot setup for OpenClaw

This guide explains how to create a Telegram bot and register it with OpenClaw. Use it with either the **secure-client** (Docker) or **openclaw-raw** (native) deployment.

## 1) Create a Telegram bot

You need a bot token from Telegram's BotFather. This is a one-time setup per bot.

1. Open Telegram and search for **@BotFather**.
2. Start a chat and send: `/newbot`
3. Follow the prompts:
   - Choose a **name** for your bot (e.g. "My OpenClaw Agent").
   - Choose a **username** ending in `bot` (e.g. `my_openclaw_bot`).
4. BotFather replies with a token like `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`.
5. Copy and store the token securely. You will use it when registering the channel.

Do not commit real bot tokens. Add them to `.env` or paste only when prompted by the CLI.

## 2) Prerequisites

- Gateway running (Docker or native).
- Agent pack installed (e.g. Messy Virgo from `messyvirgo-openclaw-agents`).
- `.env` loaded with `MESSY_VIRGO_API_KEY` and `MESSY_VIRGO_MCP_URL` if your agents need them.

## 3) Register the channel

Replace `<account>`, `<agent-name>`, and `<telegram_bot_token>` with your values.

**Docker (secure-client):**

```bash
./secure-client/scripts/cli.sh channels add --channel telegram --account <account> --name "<agent-name>" --token "<telegram_bot_token>"
./secure-client/scripts/cli.sh agents bind --agent <agent-name> --bind telegram:<account>
```

**Native (openclaw-raw):**

```bash
./openclaw-raw/scripts/cli.sh channels add --channel telegram --account <account> --name "<agent-name>" --token "<telegram_bot_token>"
./openclaw-raw/scripts/cli.sh agents bind --agent <agent-name> --bind telegram:<account>
```

Example for the Messy Virgo Team 1 Manager-Agent:

```bash
# Docker
./secure-client/scripts/cli.sh channels add --channel telegram --account mv-t1 --name "mv-t1-mngr" --token "<telegram_bot_token>"
./secure-client/scripts/cli.sh agents bind --agent mv-t1-mngr --bind telegram:mv-t1

# Native
./openclaw-raw/scripts/cli.sh channels add --channel telegram --account mv-t1 --name "mv-t1-mngr" --token "<telegram_bot_token>"
./openclaw-raw/scripts/cli.sh agents bind --agent mv-t1-mngr --bind telegram:mv-t1
```

## 4) Group policy

**Open access (anyone in the group can use the bot):**

```bash
# Docker
./secure-client/scripts/cli.sh config set channels.telegram.groupPolicy '"open"'
./secure-client/scripts/cli.sh config set channels.telegram.accounts.<account>.groupPolicy '"open"'

# Native
./openclaw-raw/scripts/cli.sh config set channels.telegram.groupPolicy '"open"'
./openclaw-raw/scripts/cli.sh config set channels.telegram.accounts.<account>.groupPolicy '"open"'
```

**Restricted (only specific Telegram user IDs):**

```bash
# Docker
./secure-client/scripts/cli.sh config set channels.telegram.accounts.<account>.groupAllowFrom '["tg:<telegram_user_id>"]'

# Native
./openclaw-raw/scripts/cli.sh config set channels.telegram.accounts.<account>.groupAllowFrom '["tg:<telegram_user_id>"]'
```

Replace `<telegram_user_id>` with the Telegram user ID you want to allow.

## 5) Restart after channel changes

Channel and binding changes require a gateway restart.

**Docker:**

```bash
./secure-client/scripts/down.sh
./secure-client/scripts/up.sh
```

**Native:**

Stop the gateway (Ctrl+C in its terminal), then:

```bash
./openclaw-raw/scripts/gateway.sh
```

## 6) Verify

```bash
# Docker
./secure-client/scripts/cli.sh channels list
./secure-client/scripts/cli.sh agents list --bindings

# Native
./openclaw-raw/scripts/cli.sh channels list
./openclaw-raw/scripts/cli.sh agents list --bindings
```

## 7) Approve pairing

When you first message the bot, it asks to pair and gives a code. If not, say "Hi".

```bash
# Docker
./secure-client/scripts/cli.sh pairing approve telegram <pairing_code>

# Native
./openclaw-raw/scripts/cli.sh pairing approve telegram <pairing_code>
```

Done. You can start chatting with your agent on Telegram.
