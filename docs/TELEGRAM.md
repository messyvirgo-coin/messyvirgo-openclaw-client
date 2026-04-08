# Telegram

Prereqs: gateway running; bot token from [@BotFather](https://t.me/BotFather) (`/newbot`). Never commit tokens.

Optional Messy Virgo shell API: `MV_API_URL` + `MV_API_KEY` in `.env` (see `.env` examples).

Use **`./openclaw-secure/scripts/cli.sh`** below, or the same commands with **`./openclaw-raw/scripts/cli.sh`** for native.

## Register + bind (default `main` agent)

```bash
./openclaw-secure/scripts/cli.sh channels add --channel telegram --account main --name "Messy Virgo" --token "<token>"
./openclaw-secure/scripts/cli.sh agents bind --agent main --bind telegram:main
```

## Groups (allowlist example)

```bash
./openclaw-secure/scripts/cli.sh config set channels.telegram.groupPolicy '"allowlist"'
./openclaw-secure/scripts/cli.sh config set channels.telegram.accounts.main.groupPolicy '"allowlist"'
./openclaw-secure/scripts/cli.sh config set channels.telegram.accounts.main.groupAllowFrom '["tg:<numeric_user_id>"]'
```

Restart gateway, then DM the bot; approve pairing:

```bash
./openclaw-secure/scripts/cli.sh pairing approve telegram <code>
```

Upstream: [Telegram channel](https://docs.openclaw.ai/channels/telegram).
