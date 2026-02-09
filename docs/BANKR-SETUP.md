# Bankr skill setup (Docker)

The **bankr** skill reads its config from `~/.clawdbot/skills/bankr/config.json` inside the container. This repo sets that up so you can edit the file on the host.

## Installing the official Bankr skills

To install or update skills from [BankrBot/openclaw-skills](https://github.com/BankrBot/openclaw-skills) (including bankr) into your workspace:

```bash
./scripts/install-openclaw-skills.sh
```

This clones the repo and copies all 13 skills (bankr, base, botchan, clanker, endaoment, ens-primary-name, erc-8004, neynar, onchainkit, qrcoin, veil, yoink, zapper) into `$OPENCLAW_WORKSPACE_DIR/skills/`. Restart the gateway after installing.

## What was done (config)

1. **Volume mount**  
   `docker-compose.yml` now mounts your host directory  
   `$OPENCLAW_CONFIG_DIR/clawdbot`  
   at `/home/node/.clawdbot` in the gateway and CLI containers. So anything you put in `…/clawdbot/skills/bankr/` on the host is visible there.

2. **Config template**  
   Example config: `config/clawdbot/skills/bankr/config.json.example`  
   It contains a single `apiKey` field. If the bankr skill expects different or extra keys, edit the JSON to match its `SKILL.md` or ClawHub docs.

## One-time setup

From the repo root:

```bash
./scripts/setup-bankr.sh
```

This creates `$OPENCLAW_CONFIG_DIR/clawdbot/skills/bankr/config.json` from the example (if it doesn’t already exist).

## Add your API key

1. Open the config on the host, for example:
   - `~/.openclaw-secure/clawdbot/skills/bankr/config.json`  
   - or `$OPENCLAW_CONFIG_DIR/clawdbot/skills/bankr/config.json` (if you set that in `.env`).

2. Replace `bk_YOUR_KEY_HERE` with your real Bankr API key (from [bankr.bot/api](https://bankr.bot/api)). The key must have **Agent API** access. Keep `apiUrl` as `https://api.bankr.bot` unless you use a different endpoint.

3. Restart the gateway so it picks up the file:
   ```bash
   ./scripts/down.sh
   ./scripts/up.sh
   ```

After that, the bankr skill should be able to read the config. If the skill expects a different JSON shape (e.g. more fields), update the example and your `config.json` to match.
