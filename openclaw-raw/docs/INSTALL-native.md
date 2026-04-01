# Native OpenClaw install (no Docker)

This guide sets up OpenClaw to run directly on the host (no containers), using this repo's configuration, models, agents, and skills.

Use the **openclaw-secure** (Docker) path if you prefer container isolation. Use **openclaw-raw** when you want lower latency, easier debugging, or run where Docker is not available.

## Prerequisites

- Node.js 18+ and npm
- OpenClaw installed globally: `npm install -g openclaw`
- This repo cloned locally

## 1) Prepare `.env`

From the repo root:

```bash
cp .env.example .env
```

Edit `.env` and set:

- `OPENROUTER_API_KEY`, `BRAVE_API_KEY` (for model providers you use)
- `OPENCLAW_WORKSPACES_DIR` (default: `$HOME/OpenClawWorkspaces`)
- `OPENCLAW_SKILLS_DIR` (optional; use relative `skills` for portability, or leave empty to default to `<repo>/skills`)
- `OPENCLAW_CONFIG_DIR` (default: `$HOME/.openclaw`)
- `OPENCLAW_GATEWAY_TOKEN` (leave empty to auto-generate on first setup)
- `OPENCLAW_GATEWAY_PORT` (default: 18789)

## 2) Bootstrap

```bash
./openclaw-raw/scripts/setup.sh
```

This creates the config directory, copies `config/openclaw.native.json` to `$OPENCLAW_CONFIG_DIR/openclaw.json`, deploys workspace templates, and generates a gateway token if missing.

## 3) Start the gateway

```bash
./openclaw-raw/scripts/gateway.sh
```

Or with explicit port and bind:

```bash
./openclaw-raw/scripts/gateway.sh --port 18789 --bind lan
```

## 4) Open the dashboard

The dashboard requires the gateway token in the URL. Run:

```bash
./openclaw-raw/scripts/dashboard.sh
```

This prints the tokenized URL (e.g. `http://127.0.0.1:18789/#token=...`). Open that URL in your browser. Without the token, you will see an unauthorized or empty start page.

## 5) Run CLI commands

```bash
./openclaw-raw/scripts/cli.sh status
./openclaw-raw/scripts/cli.sh channels list
./openclaw-raw/scripts/cli.sh agent --agent main --message "Hello"
```

Or source `.env` and use `openclaw` directly:

```bash
set -a && source .env && set +a
export OPENCLAW_CONFIG_PATH=$OPENCLAW_CONFIG_DIR/openclaw.json
export OPENCLAW_STATE_DIR=$OPENCLAW_CONFIG_DIR
export OPENCLAW_WORKSPACES_DIR
openclaw status
```

## Config files

| Mode   | Template                 | Deployed as                         |
|--------|--------------------------|-------------------------------------|
| Docker | `config/openclaw.json`   | `$OPENCLAW_CONFIG_DIR/openclaw.json` |
| Native | `config/openclaw.native.json` | `$OPENCLAW_CONFIG_DIR/openclaw.json` |

The native template uses `${OPENCLAW_WORKSPACES_DIR}` and other vars. `OPENCLAW_SKILLS_DIR` is optional; when set, setup/upgrade inject it into the config so OpenClaw does not require it at runtime. Export `OPENCLAW_WORKSPACES_DIR` when running the gateway or CLI directly (our scripts do this automatically).

## Running as a service

**Linux (systemd user):**

```bash
openclaw gateway install
systemctl --user enable --now openclaw-gateway
```

Ensure the service unit inherits `OPENCLAW_CONFIG_PATH`, `OPENCLAW_WORKSPACES_DIR`, and your API keys (e.g. via `EnvironmentFile=`). `OPENCLAW_SKILLS_DIR` is optional; when set at setup time it is injected into the config.

**macOS (launchd):**

```bash
openclaw gateway install
```

See OpenClaw docs for service configuration details.

## Agent packs

To install Messy Virgo agents from `messyvirgo-openclaw-agents`:

```bash
cd ../messyvirgo-openclaw-agents
./scripts/install.sh --target native --profile <profile>
```

(Confirm the pack supports `--target native`; otherwise adapt the install steps for native config paths.)

## Optional: Telegram

To connect an agent to Telegram, create a bot via @BotFather, then register the channel with OpenClaw. See [docs/TELEGRAM.md](../../docs/TELEGRAM.md) for the full flow.

**Native commands** (replace placeholders with your values):

```bash
./openclaw-raw/scripts/cli.sh channels add --channel telegram --account <account> --name "<agent-name>" --token "<telegram_bot_token>"
./openclaw-raw/scripts/cli.sh agents bind --agent <agent-name> --bind telegram:<account>
```

After channel changes, restart the gateway (Ctrl+C, then `./openclaw-raw/scripts/gateway.sh`).

## Upgrading

To upgrade OpenClaw and optionally sync config or workspace templates:

```bash
./openclaw-raw/scripts/upgrade.sh
```

Options:

- `--sync-workspaces` – Overwrite changed workspace templates (creates timestamped backups)
- `--sync-config` – Overwrite `openclaw.json` from `config/openclaw.native.json` (creates backup)
- `--cleanup-bootstrap` – Remove `BOOTSTRAP.md` from deployed workspaces
- `--dry-run` – Show what would change without applying

**Troubleshooting:** If you see `missing env var "OPENCLAW_SKILLS_DIR"` when running `openclaw` directly, the config still references the old template. Run `./openclaw-raw/scripts/upgrade.sh --sync-config` to update it (creates a backup). Skills from `OPENCLAW_SKILLS_DIR` are optional.
