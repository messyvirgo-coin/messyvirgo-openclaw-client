# API keys and setup overwrites

When you run `./scripts/setup.sh`, it overwrites `.env` with core OpenClaw variables (paths, token, image). Any API keys you had in `.env` would be lost—and if you update OpenClaw or pull a new `setup.sh`, the in-script preservation logic may not be there.

## Automated approach: `.env.api-keys` (recommended)

1. **One-time:** Copy the example and add your keys:
   ```bash
   cp env.api-keys.example .env.api-keys
   # Edit .env.api-keys and set OPENAI_API_KEY, OPENROUTER_API_KEY, XAPI_IO_API_KEY, MOLTBOOK_API_KEY, etc.
   ```

2. **Every time you run `./scripts/up.sh`:** The script runs `scripts/merge-env-api-keys.sh`, which appends any key from `.env.api-keys` that is not already in `.env` into `.env`.

3. **After running setup (including after an OpenClaw update):** Setup overwrites `.env`. The next time you run `./scripts/up.sh`, the merge runs and your API keys from `.env.api-keys` are added back into `.env`. No manual re-adding needed.

So: keep your API keys only in `.env.api-keys` (or put them there after the first time setup wipes `.env`). They are merged into `.env` automatically on every `up.sh`. The file `.env.api-keys` is gitignored (via `.env.*`).

## Keys that are merged

- `OPENAI_API_KEY` — OpenAI models
- `OPENROUTER_API_KEY` — OpenRouter models (e.g. Claude via OpenRouter)
- `XAPI_IO_API_KEY` — X Monitor dashboard + x-api skill
- `MOLTBOOK_API_KEY` — Moltbook skill
- Optional: `DASHBOARD_X_PORT`, `GITHUB_TOKEN`, `GIT_PAT`, `OPENCLAW_WATCHDOG_*`

Ensure these are passed into the gateway/CLI in `docker-compose.yml` (they are referenced there); the merge only puts them into `.env` so that Compose can substitute them.
