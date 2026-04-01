# Linux install (beginner-friendly)

This guide always starts with the secure OpenClaw client in this repo, then optionally shows how to install Messy Virgo agents and connect Telegram:

- installing the OpenClaw-secure wrapper
- opening the dashboard
- approving the first browser/device pairing
- running basic smoke checks
- optionally installing agents from `messyvirgo-openclaw-agents`
- optionally registering Telegram channels/bindings for those agents

The agent pack itself still lives in the separate `messyvirgo-openclaw-agents` repo, but the Telegram channel registration happens back in this repo.

## 0) Requirements

- Docker Engine + Docker Compose v2 (`docker compose` must work)
- Optional but recommended: your user is in the `docker` group
- This repo cloned locally

Test Docker first:

```bash
docker info
docker compose version
```

If you still need to clone the repo:

```bash
git clone https://github.com/messyvirgo-coin/messyvirgo-openclaw-client.git
cd messyvirgo-openclaw-client
```

## 1) Prepare `.env`

Before setup, create `.env` so your API keys are present on first boot:

```bash
cp .env.example .env
```

Open `.env` and set any values you already have:

- `OPENROUTER_API_KEY` for OpenRouter model provider
- `BRAVE_API_KEY` for web search

If you plan to install the Messy Virgo Agents & Skills Pack, add these values now:

- `MESSY_VIRGO_MCP_URL` with value `https://api.messyvirgo.com/mcp`
- `MESSY_VIRGO_API_KEY` with your API key

If your MCP server runs locally on the same Linux host:

- with `./openclaw-secure/scripts/up.sh`, usually use `http://172.17.0.1:8000/mcp`
- with `./openclaw-secure/scripts/up-linux-hostnet.sh`, use `http://localhost:8000/mcp`

Other values you can optionally edit in `.env` before running setup:

- **`OPENCLAW_GIT_REPO`**: source repo to clone/pull (default: upstream [`openclaw/openclaw`](https://github.com/openclaw/openclaw); override for a fork or mirror)
- **`OPENCLAW_SRC_DIR`**: local source checkout used to build the Docker image
- **`OPENCLAW_IMAGE`**: image name to build locally
- **`OPENCLAW_CONFIG_DIR`** and **`OPENCLAW_WORKSPACES_DIR`**: host state/workspace paths

## 2) Run one-time setup

From the repo folder:

```bash
./openclaw-secure/scripts/setup.sh
```

`setup.sh` reads config from `.env` and uses defaults from `.env.example` when values are missing.

If you prefer prompts, run `./openclaw-secure/scripts/setup.sh --interactive`.

Important:

- choose a dedicated workspace root, not your whole home directory
- `setup.sh` already builds the image, writes `.env`, deploys config/workspace templates, and starts the gateway
- because `setup.sh` starts the gateway, you can go directly to step 3 without running `./openclaw-secure/scripts/up.sh`

## 3) Open the dashboard

Print the tokenized dashboard URL:

```bash
./openclaw-secure/scripts/dashboard.sh
```

Open the full URL that includes `#token=...`.

Notes:

- opening `http://127.0.0.1:18789/` without the token may show `unauthorized`
- on Linux, the dashboard should stay bound to `127.0.0.1`

## 4) Approve the first device pairing

On a fresh install, the browser may show `pairing required`. If that happens, approve the pending device from the host terminal:

```bash
./openclaw-secure/scripts/cli.sh devices list
./openclaw-secure/scripts/cli.sh devices approve <requestId>
```

How to get `<requestId>`:

1. Run `./openclaw-secure/scripts/cli.sh devices list`
2. Find the pending pairing entry for your browser/device
3. Copy its `requestId` value
4. Run `./openclaw-secure/scripts/cli.sh devices approve <requestId>` with that exact value

If there are multiple pending entries, approve the newest one first (or approve each pending request once).

Then refresh the dashboard page.

If you are using a different browser profile, incognito window, or another device, you may need to approve a new pairing request again.

## 5) Two ways to run CLI commands

You can run / execute the OpenClaw CLI in the docker container with either of these ways:

Option A: one command at a time from the host:

```bash
./openclaw-secure/scripts/cli.sh status
./openclaw-secure/scripts/cli.sh channels list
```

Option B: open an interactive shell, then use the `openclaw` helper inside it:

```bash
./openclaw-secure/scripts/cli-shell.sh
openclaw status
openclaw channels list
```

Use `./openclaw-secure/scripts/cli.sh ...` when you want a single command from the host terminal. Use `./openclaw-secure/scripts/cli-shell.sh` when you want an interactive CLI session and shorter `openclaw ...` commands.

## 6) Run quick smoke checks

From the repo folder:

```bash
./openclaw-secure/scripts/cli.sh health --json
./openclaw-secure/scripts/cli.sh status
./openclaw-secure/scripts/security-audit.sh
```

Optional identity check for the built-in wrapper agents:

```bash
./openclaw-secure/scripts/cli.sh agent --agent main --message "State your name in one sentence."
./openclaw-secure/scripts/cli.sh agent --agent mv-coder --message "State your name in one sentence."
./openclaw-secure/scripts/cli.sh agent --agent mv-researcher --message "State your name in one sentence."
./openclaw-secure/scripts/cli.sh agent --agent mv-planner --message "State your name in one sentence."
```

If an agent behaves like first-run onboarding, the workspace may still contain a `BOOTSTRAP.md`. Restart after cleanup or rerun setup with the appropriate cleanup option.

## 7) Optional: install Messy Virgo agents and register Telegram

Skip this section if you only want the OpenClaw-secure wrapper and built-in agents.

### 7.1 Add Messy Virgo credentials

If you want to install Messy Virgo agents, make sure you added these values to this repo's `.env` before installing the agent pack:

```bash
MESSY_VIRGO_MCP_URL=https://api.messyvirgo.com/mcp
MESSY_VIRGO_API_KEY=<your_messy_virgo_api_key>
```

If the MCP server runs locally on the same Linux host, use this shortcut:

- `./openclaw-secure/scripts/up.sh` -> usually `MESSY_VIRGO_MCP_URL=http://172.17.0.1:8000/mcp`
- `./openclaw-secure/scripts/up-linux-hostnet.sh` -> `MESSY_VIRGO_MCP_URL=http://localhost:8000/mcp`

Do not commit real keys or bot tokens.

### 7.2 Install the agent pack from the agents repo

Use the `messyvirgo-openclaw-agents` repo:

- Git repo: `https://github.com/messyvirgo-coin/messyvirgo-openclaw-agents`

If you still need to clone it:

```bash
git clone https://github.com/messyvirgo-coin/messyvirgo-openclaw-agents.git
cd messyvirgo-openclaw-agents
```

In your local checkout of the agent's repo (set real path to this client repo):

```bash
set -a
source /path/to/messyvirgo-openclaw-client/.env
set +a
./scripts/install.sh --target wrapper --profile <profile>
```

Replace `<profile>` with the agent profile you want to install, for example `mv-t1`.

Example for `mv-t1` profile:

```bash
set -a
source ../messyvirgo-openclaw-client/.env
set +a
./scripts/install.sh --target wrapper --profile mv-t1
```

Return to your local `messyvirgo-openclaw-client` checkout after the pack install and restart the gateway to be on the safe side:

```bash
./openclaw-secure/scripts/down.sh
./openclaw-secure/scripts/up.sh
```

MCP runtime note:

- The pack writes one global MCP runtime config at `OPENCLAW_CONFIG_DIR/mcporter.json` (wrapper default: `~/.openclaw-secure/mcporter.json`).
- You do **not** need a `mcporter.json` in each agent workspace.
- Wrapper images built from this repo include `mcporter` and auto-read that global config path.

Quick MCP verification (optional, recommended):

```bash
./openclaw-secure/scripts/cli.sh agent --local --agent mv-t1-mngr --message "Run mcporter call messy-virgo-funds.list_accessible_funds and return only the JSON output."
```

### 7.3 Register a Telegram channel back in this repo

If you don't have a bot token yet, see [docs/TELEGRAM.md](../../docs/TELEGRAM.md) for how to create one via @BotFather.

To register a telegram channel for an agent, you can use either command style below.

Host wrapper style:

```bash
./openclaw-secure/scripts/cli.sh channels add --channel telegram --account <account> --name "<agent-name>" --token "<telegram_bot_token>"
./openclaw-secure/scripts/cli.sh agents bind --agent <agent-name> --bind telegram:<account>
```

Interactive shell style:

```bash
./openclaw-secure/scripts/cli-shell.sh
openclaw channels add --channel telegram --account <account> --name "<agent-name>" --token "<telegram_bot_token>"
openclaw agents bind --agent <agent-name> --bind telegram:<account>
```

In the following we skip providing both styles. Simply exchange `./openclaw-secure/scripts/cli.sh` with `openclaw` in the interactive shell.

Full example to register the 'Messy Virgo Team 1' Manager-Agent:

```bash
./openclaw-secure/scripts/cli.sh channels add --channel telegram --account mv-t1 --name "mv-t1-mngr" --token "<telegram_bot_token>"
./openclaw-secure/scripts/cli.sh agents bind --agent mv-t1-mngr --bind telegram:mv-t1
```

### 7.4 Choose Telegram group policy

The safe baseline for group chats is `allowlist`.

```bash
# default
./openclaw-secure/scripts/cli.sh config set channels.telegram.groupPolicy '"allowlist"'

# per account
./openclaw-secure/scripts/cli.sh config set channels.telegram.accounts.<account>.groupPolicy '"allowlist"'
./openclaw-secure/scripts/cli.sh config set channels.telegram.accounts.<account>.groupAllowFrom '["tg:<telegram_user_id>"]'
```

Replace `<telegram_user_id>` with the numeric Telegram user ID you want to allow. If you do not know the IDs yet, keep the group restricted and have the trusted users pair in DM first.

Full example for the 'Messy Virgo Team 1' Manager-Agent:

```bash
./openclaw-secure/scripts/cli.sh config set channels.telegram.groupPolicy '"allowlist"'
./openclaw-secure/scripts/cli.sh config set channels.telegram.accounts.mv-t1.groupPolicy '"allowlist"'
./openclaw-secure/scripts/cli.sh config set channels.telegram.accounts.mv-t1.groupAllowFrom '["tg:<telegram_user_id>"]'
```

Mandatory restart after channel changes

```bash
./openclaw-secure/scripts/down.sh
./openclaw-secure/scripts/up.sh
```

### 7.5 Verify the channel and bindings

```bash
./openclaw-secure/scripts/cli.sh channels list
./openclaw-secure/scripts/cli.sh agents list --bindings
```

### 7.6 Approve Telegram pairing codes

Your telegram bot should have asked you to pair and provided you with a code. If not, say politely 'Hi'.

```bash
./openclaw-secure/scripts/cli.sh pairing approve telegram <pairing_code>
```

Done. Have a chat!

## 8) Start/stop later

Start:

```bash
./openclaw-secure/scripts/up.sh
```

Logs:

```bash
./openclaw-secure/scripts/logs.sh
```

Stop:

```bash
./openclaw-secure/scripts/down.sh
```

## 9) Upgrade later

To pull the latest source, rebuild the image, and restart:

```bash
./openclaw-secure/scripts/upgrade.sh
```

Your config and data are preserved.

## Common issues

### “permission denied” / “Cannot connect to the Docker daemon”

Option A (quick fix):

```bash
sudo ./openclaw-secure/scripts/setup.sh
```

Option B (recommended): add your user to the `docker` group, then log out and back in once:

```bash
sudo usermod -aG docker "$USER"
```

### Dashboard opens but pairing keeps looping

1. Make sure you opened the full tokenized URL from `./openclaw-secure/scripts/dashboard.sh`
2. Approve the pending device with `./openclaw-secure/scripts/cli.sh devices list` and `./openclaw-secure/scripts/cli.sh devices approve <requestId>`
3. If needed, restart and reopen:

```bash
./openclaw-secure/scripts/down.sh
./openclaw-secure/scripts/up.sh
./openclaw-secure/scripts/dashboard.sh
```

### “gateway token mismatch”

Restart the gateway and reopen the tokenized URL:

```bash
./openclaw-secure/scripts/down.sh
./openclaw-secure/scripts/up.sh
./openclaw-secure/scripts/dashboard.sh
```

If the dashboard has stored an old token, paste the current token from `.env` into Control UI settings.

### Port already in use (`18789` / `18790`)

You can change these values in `.env`:

- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

After changing them:

```bash
./openclaw-secure/scripts/down.sh
./openclaw-secure/scripts/up.sh
./openclaw-secure/scripts/dashboard.sh
```
