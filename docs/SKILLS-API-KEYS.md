# Skills: API Keys and Config

This doc summarizes which of your installed OpenClaw skills need API keys or config to work, and what is missing (from a one-time agent check and upstream skill metadata).

---

## Skills that work without API keys (or only need curl)

| Skill | Notes |
|-------|--------|
| **healthcheck** | No API key. |
| **skill-creator** | No API key. |
| **weather** | No API key; uses wttr.in and Open-Meteo (curl). |

---

## Skills that need API keys or config

### 1. OpenAI (bundled skills)

| Skill | Required | Where to set (Docker) |
|-------|----------|------------------------|
| **openai-image-gen** | `OPENAI_API_KEY` | Add to `.env` and pass into the gateway container (see below), or set in `openclaw.json` under `skills.entries["openai-image-gen"].apiKey`. |
| **openai-whisper-api** | `OPENAI_API_KEY` | Same as above. |

To pass an API key from your host into the gateway, add to `.env`:

```bash
OPENAI_API_KEY=sk-...
```

Then in `docker-compose.yml` under `openclaw-gateway` → `environment`, add:

```yaml
OPENAI_API_KEY: ${OPENAI_API_KEY:-}
```

(Alternatively, configure the key only in `openclaw.json` under `skills.entries` so it is not in `.env`.)

---

### 2. Moltbook

| Skill | Required | Status from check |
|-------|----------|--------------------|
| **moltbook** | `MOLTBOOK_API_KEY` and/or `~/.config/moltbook/credentials.json` | `credentials.json` was **missing** in the container. |

- `MOLTBOOK_API_KEY` is already in `docker-compose.yml` for the gateway; set it in `.env` if you use it.
- If the skill expects `~/.config/moltbook/credentials.json`, that path inside the container is under the mounted config dir. Create it on the host at `$OPENCLAW_CONFIG_DIR/config/moltbook/credentials.json` (or ensure the skill’s docs for “credentials” path match your mount).

---

### 3. Skills that expect config/credentials under `~/.clawdbot/skills/`

When the agent ran, it tried to read these and they were **missing**:

| Skill | Missing path (inside container) | Setup in this repo |
|-------|----------------------------------|---------------------|
| **bankr** | `/home/node/.clawdbot/skills/bankr/config.json` | **Done.** Run `./scripts/setup-bankr.sh`, then edit the created `config.json` and add your API key. See [BANKR-SETUP.md](BANKR-SETUP.md). |
| **neynar** | `/home/node/.clawdbot/skills/neynar/config.json` | Mount added; create the file and config manually. |
| **veil** | `/home/node/.clawdbot/skills/veil/.env` | Mount added; create the file and env vars manually. |

The Compose file now mounts `$OPENCLAW_CONFIG_DIR/clawdbot` at `/home/node/.clawdbot`, so you can create and edit these files on the host. For **bankr**, use the setup script and doc above.

---

## Summary

- **Ready to use without keys:** healthcheck, skill-creator, weather.  
- **Need OpenAI key:** openai-image-gen, openai-whisper-api — set `OPENAI_API_KEY` (and optionally wire it via Compose).  
- **Moltbook:** set `MOLTBOOK_API_KEY` in `.env` and/or add `credentials.json` under the config dir.  
- **bankr, neynar, veil:** add the missing config/credentials under `~/.clawdbot/skills/<skill>/` (or equivalent mount).

The remaining skills (base, botchan, clanker, endaoment, ens-primary-name, erc-8004, messyvirgo-macro-report, onchainkit, qrcoin, yoink, zapper) were not seen to fail on a missing file in that run; they may still require API keys or config. Check each skill’s `SKILL.md` in your workspace (`$OPENCLAW_WORKSPACE_DIR/skills/<name>/`) or on ClawHub for `metadata.openclaw.requires` (env, config) and create the needed keys/files accordingly.
