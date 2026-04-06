# Telegram bot setup for OpenClaw

This guide explains how to create a Telegram bot and register it with OpenClaw. Use it with either the **openclaw-secure** (Docker) or **openclaw-raw** (native) deployment.

For a map of all wrapper docs and upstream links, see [OPENCLAW.md](OPENCLAW.md).

## Streaming and “internal” text in chat

`channels.telegram.streaming` controls **live preview** edits (`off` | `partial` | `block` | `progress`). Upstream’s common default is `partial`, which updates a preview message as the model generates text.

This wrapper template sets **`streaming` to `off`** so Telegram users only see **final** outbound text. That reduces cases where draft assistant text (including model-written fragments that look like tool markup, or other pre-final content) appears in the chat. If you want typing-style previews again, set `channels.telegram.streaming` to `"partial"` in `$OPENCLAW_CONFIG_DIR/openclaw.json` and restart the gateway—see [Telegram streaming](https://docs.openclaw.ai/channels/telegram#live-stream-preview-message-edits).

**If you still see `<tool>…</tool>`-style text in a finished message**, the model is likely emitting that as **plain assistant text** instead of using native tool calls reliably (provider/model dependent). Fix paths: use a model known to tool-call well on your gateway, or adjust the agent pack / system instructions so it does not role-play tools as XML. `commands.ownerDisplay` (`raw` vs `hash`) only affects how **owner IDs** appear in the agent system prompt, not tool visibility.

**Weird `(http://…/)` inside SQL in Telegram**: Telegram’s HTML/linkifier can turn fragments like `f.id` in `f.id AS fund_id` into links, corrupting the displayed command. That is a display artifact, not OpenClaw rewriting your query.

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
- An agent profile in config to bind the channel to (wrapper defaults include several agents; Messy Virgo pack agents are optional).
- If you use Messy Virgo MCP tools, set `MESSY_VIRGO_API_KEY` and `MESSY_VIRGO_MCP_URL` in `.env` (see the agent pack docs).

## 3) Register the channel

The wrapper baseline sets `channels.telegram.defaultAccount` to `main` in `config/openclaw.json` and `config/openclaw.native.json`, so the primary Messy Virgo bot should use Telegram **account id** `main` (the OpenClaw agent id for the default profile is also `main`). Register the token under that account id so default routing matches.

Replace `<account>`, `<agent-name>`, and `<telegram_bot_token>` with your values.

**Docker (openclaw-secure):**

```bash
./openclaw-secure/scripts/cli.sh channels add --channel telegram --account <account> --name "<agent-name>" --token "<telegram_bot_token>"
./openclaw-secure/scripts/cli.sh agents bind --agent <agent-name> --bind telegram:<account>
```

**Native (openclaw-raw):**

```bash
./openclaw-raw/scripts/cli.sh channels add --channel telegram --account <account> --name "<agent-name>" --token "<telegram_bot_token>"
./openclaw-raw/scripts/cli.sh agents bind --agent <agent-name> --bind telegram:<account>
```

Example for the default Messy Virgo agent (`main`):

```bash
# Docker
./openclaw-secure/scripts/cli.sh channels add --channel telegram --account main --name "Messy Virgo" --token "<telegram_bot_token>"
./openclaw-secure/scripts/cli.sh agents bind --agent main --bind telegram:main

# Native
./openclaw-raw/scripts/cli.sh channels add --channel telegram --account main --name "Messy Virgo" --token "<telegram_bot_token>"
./openclaw-raw/scripts/cli.sh agents bind --agent main --bind telegram:main
```

For an extra bot (different Telegram account id), use another `--account` value and set per-account policy as in the next section; only one account should match `defaultAccount` unless you change that key in config.

## 4) Group policy

The safe baseline for group chats is `allowlist`. Telegram group restrictions are based on numeric Telegram user IDs, not usernames.

If you do not yet know the trusted users' IDs, keep the group restricted and have them pair in DM first.

```bash
# Docker
./openclaw-secure/scripts/cli.sh config set channels.telegram.groupPolicy '"allowlist"'
./openclaw-secure/scripts/cli.sh config set channels.telegram.accounts.<account>.groupPolicy '"allowlist"'
./openclaw-secure/scripts/cli.sh config set channels.telegram.accounts.<account>.groupAllowFrom '["tg:<telegram_user_id>"]'

# Native
./openclaw-raw/scripts/cli.sh config set channels.telegram.groupPolicy '"allowlist"'
./openclaw-raw/scripts/cli.sh config set channels.telegram.accounts.<account>.groupPolicy '"allowlist"'
./openclaw-raw/scripts/cli.sh config set channels.telegram.accounts.<account>.groupAllowFrom '["tg:<telegram_user_id>"]'
```

Replace `<telegram_user_id>` with the numeric Telegram user ID you want to allow. If you intentionally want an open trusted group, set `groupPolicy` back to `"open"` for that account only.

## 5) Restart after channel changes

Channel and binding changes require a gateway restart.

**Docker:**

```bash
./openclaw-secure/scripts/down.sh
./openclaw-secure/scripts/up.sh
```

**Native:**

Stop the gateway (Ctrl+C in its terminal), then:

```bash
./openclaw-raw/scripts/gateway.sh
```

## 6) Verify

```bash
# Docker
./openclaw-secure/scripts/cli.sh channels list
./openclaw-secure/scripts/cli.sh agents list --bindings

# Native
./openclaw-raw/scripts/cli.sh channels list
./openclaw-raw/scripts/cli.sh agents list --bindings
```

## 7) Approve pairing

When you first message the bot, it asks to pair and gives a code. If not, say "Hi".

```bash
# Docker
./openclaw-secure/scripts/cli.sh pairing approve telegram <pairing_code>

# Native
./openclaw-raw/scripts/cli.sh pairing approve telegram <pairing_code>
```

Done. You can start chatting with your agent on Telegram.
