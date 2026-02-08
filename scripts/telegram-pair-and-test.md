# Telegram: pair and test

Your bot uses **pairing** by default: the first time someone DMs it, they get a **pairing code** and the message is not processed until you approve.

## 1. Send a message to your bot

1. Open **Telegram** and find your bot (the one whose token is in `channels.telegram.botToken` in config).
2. Start a chat (e.g. tap **Start** or send any message like `Hello` or `/start`).
3. The bot should reply with a **pairing code** (e.g. `Your pairing code: ABCD1234`) and ask you to approve it.

If the bot **does not reply at all**, see "Debug: bot not reacting" below.

## 2. List and approve the pairing

In this repo directory run:

```bash
# List pending pairing requests (you should see the code you got in Telegram)
./scripts/cli.sh pairing list telegram

# Approve using the code (replace ABCD1234 with your code)
./scripts/cli.sh pairing approve telegram ABCD1234
```

After approving, send another message to the bot; it should react normally.

## 3. Debug: bot not reacting

If the bot doesn’t reply to your first message:

1. **Check the gateway is running**
   ```bash
   ./scripts/up.sh
   ./scripts/logs.sh
   ```
   Look for `[telegram] [default] starting provider` and any errors.

2. **Check pairing requests**
   ```bash
   ./scripts/cli.sh pairing list telegram
   ```
   If you see a code here but never got a reply in Telegram, the bot may not be sending messages (e.g. wrong token or Telegram API issue).

3. **Check gateway log file** (inside the container)
   ```bash
   docker exec messyvirgo-openclaw-client-main-openclaw-gateway-1 cat /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log | grep -i telegram
   ```

4. **Confirm the token**  
   The token in `~/.openclaw-secure/openclaw.json` under `channels.telegram.botToken` must be the one from @BotFather for this bot. If you changed it, restart the gateway: `./scripts/down.sh && ./scripts/up.sh`.

5. **Only one gateway**  
   If another OpenClaw instance (or the same bot) is running elsewhere, Telegram will return "409 Conflict" and the bot won’t receive updates. Stop any other instance using this bot token.

## Quick test after pairing

Once paired, send a message like:

- `Hello` or `What can you do?`

The bot should reply. If it doesn’t, check `./scripts/logs.sh` for errors.
