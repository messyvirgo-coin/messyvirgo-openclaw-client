# Native install (no Docker)

Host OpenClaw with this repo’s `config/`. For Docker: [../openclaw-secure/docs/INSTALL-docker.md](../openclaw-secure/docs/INSTALL-docker.md).

## Requirements

- Node/npm matching your `openclaw` CLI
- `npm install -g openclaw`
- This repo cloned

## 1. `.env`

```bash
cp .env.raw.example .env
```

Set at least `OPENROUTER_API_KEY`. Optional: `BRAVE_API_KEY`, `TAVILY_API_KEY`, `OPENCLAW_CONFIG_DIR`, `OPENCLAW_WORKSPACES_DIR`, `OPENCLAW_GATEWAY_TOKEN` (empty = generated on setup), `OPENCLAW_GATEWAY_PORT`, `MV_API_URL` / `MV_API_KEY`.

## 2. Bootstrap

```bash
./openclaw-raw/scripts/setup.sh
```

Copies `config/openclaw.json` → `$OPENCLAW_CONFIG_DIR/openclaw.json`, then sets **native** defaults (`gateway.bind`: loopback, `sandbox.mode`: all). Installs `@messyvirgo/cli` globally.

## 3. Gateway

```bash
./openclaw-raw/scripts/gateway.sh
# optional: ./openclaw-raw/scripts/gateway.sh --port 18789 --bind lan
```

## 4. Dashboard / CLI

```bash
./openclaw-raw/scripts/dashboard.sh
./openclaw-raw/scripts/cli.sh status
```

## Config

Single template: `config/openclaw.json` → deployed `openclaw.json`. Docker and native post-process bind/sandbox differently after copy.

## Service (optional)

`openclaw gateway install` then systemd user or launchd — expose `OPENCLAW_CONFIG_PATH`, `OPENCLAW_WORKSPACES_DIR`, keys (e.g. `EnvironmentFile=`). See upstream docs.

## Telegram

[../../docs/TELEGRAM.md](../../docs/TELEGRAM.md) — use `./openclaw-raw/scripts/cli.sh` instead of `openclaw-secure`.

## Upgrade

```bash
./openclaw-raw/scripts/upgrade.sh
```

Options: `--sync-config`, `--sync-workspaces`, `--cleanup-bootstrap`, `--dry-run`.

## Memory

No extra install; `memory status --deep` when gateway is up. Reindex with `memory index --force` if you change embeddings. [../../docs/MEMORY.md](../../docs/MEMORY.md).
