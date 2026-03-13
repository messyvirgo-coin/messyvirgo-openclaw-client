# macOS install (beginner-friendly)

This guide always starts with the secure OpenClaw client in this repo, then optionally shows how to install Messy Virgo agents and connect Telegram:

- installing the secure client wrapper
- opening the dashboard
- approving the first browser/device pairing
- running basic smoke checks
- optionally installing agents from `messyvirgo-openclaw-agents`
- optionally registering Telegram channels/bindings for those agents

The agent pack itself still lives in the separate `messyvirgo-openclaw-agents` repo, but the Telegram channel registration happens back in this repo.

## 0) Requirements

- Install **Docker Desktop**
- Open Docker Desktop and wait until it says **Docker is running**
- This repo cloned locally or unpacked from a ZIP

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
- `BANKR_API_KEY` if you also enable Bankr models
- `BRAVE_API_KEY` for web search

You can leave other defaults alone for a first install.

## 2) Run one-time setup

In Terminal, from the repo folder:

```bash
./scripts/setup.sh
```

`setup.sh` reads config from `.env` and uses defaults from `.env.example` when values are missing.

Important values you can edit in `.env` before running setup:

- **`OPENCLAW_GIT_REPO`**: source repo to clone/pull (default: Messy Virgo fork; optional: upstream OpenClaw repo)
- **`OPENCLAW_SRC_DIR`**: local source checkout used to build the Docker image
- **`OPENCLAW_IMAGE`**: image name to build locally
- **`OPENCLAW_CONFIG_DIR`** and **`OPENCLAW_WORKSPACES_DIR`**: host state/workspace paths

If you prefer prompts, run `./scripts/setup.sh --interactive`.

Important:

- choose a dedicated workspace root, not your whole home directory
- `setup.sh` already builds the image, writes `.env`, deploys config/workspace templates, and starts the gateway
- because `setup.sh` starts the gateway, you can go directly to step 4 without running `./scripts/up.sh`

## 3) Important: Docker Desktop file sharing

If you chose a workspace, config directory, or source directory outside the normal locations Docker Desktop already allows, add those paths in:

- Docker Desktop → Settings → Resources → File Sharing

Then apply changes and restart Docker Desktop if prompted.

## 4) Open the dashboard

Print the tokenized dashboard URL:

```bash
./scripts/dashboard.sh
```

Open the full URL that includes `#token=...` in Safari or Chrome.

Notes:

- opening the bare dashboard URL without the token may show `unauthorized`
- on macOS, Docker Desktop may expose the dashboard on `0.0.0.0`; access is still token-protected, but network exposure is broader than strict loopback on Linux

## 5) Approve the first device pairing

On a fresh install, the browser may show `pairing required`. If that happens, approve the pending device from the host terminal:

```bash
./scripts/cli.sh devices list
./scripts/cli.sh devices approve <requestId>
```

How to get `<requestId>`:

1. Run `./scripts/cli.sh devices list`
2. Find the pending pairing entry for your browser/device
3. Copy its `requestId` value
4. Run `./scripts/cli.sh devices approve <requestId>` with that exact value

If there are multiple pending entries, approve the newest one first (or approve each pending request once).

Then refresh the dashboard page.

If you use another browser profile, incognito window, or another device, you may need to approve a new pairing request again.

## 6) Two ways to run CLI commands

You can run the same OpenClaw CLI in either of these ways:

Option A: one command at a time from the host:

```bash
./scripts/cli.sh status
./scripts/cli.sh channels list
```

Option B: open an interactive shell, then use the `openclaw` helper inside it:

```bash
./scripts/cli-shell.sh
openclaw status
openclaw channels list
```

Use `./scripts/cli.sh ...` when you want a single command from the host terminal. Use `./scripts/cli-shell.sh` when you want an interactive CLI session and shorter `openclaw ...` commands.

## 7) Run quick smoke checks

From the repo folder:

```bash
./scripts/cli.sh health --json
./scripts/cli.sh status
./scripts/security-audit.sh
```

Optional identity check for the built-in wrapper agents:

```bash
./scripts/cli.sh agent --agent main --message "State your name in one sentence."
./scripts/cli.sh agent --agent mv-coder --message "State your name in one sentence."
./scripts/cli.sh agent --agent mv-researcher --message "State your name in one sentence."
./scripts/cli.sh agent --agent mv-planner --message "State your name in one sentence."
```

## 8) Optional: install Messy Virgo agents and register Telegram

Skip this section if you only want the secure client wrapper and built-in agents.

### 8.1 Add Messy Virgo credentials

If you want to install Messy Virgo agents, add these values to this repo's `.env` before installing the agent pack:

```bash
MESSY_VIRGO_MCP_URL=https://api.messyvirgo.com/mcp
MESSY_VIRGO_API_KEY=<your_messy_virgo_api_key>
```

Do not commit real keys or bot tokens.

### 8.2 Install the agent pack from the agents repo

Use the `messyvirgo-openclaw-agents` repo:

- Git repo: `https://github.com/messyvirgo-coin/messyvirgo-openclaw-agents`

In your local checkout of that repo:

```bash
cd /path/to/messyvirgo-openclaw-agents
set -a
source /path/to/messyvirgo-openclaw-client/.env
set +a
./scripts/install.sh --target wrapper --profile <profile>
```

Replace `<profile>` with the agent profile you want to install, for example `mv-t1`.

### 8.3 Register a Telegram channel back in this repo

Return to your local `messyvirgo-openclaw-client` checkout after the pack install:

```bash
cd /path/to/messyvirgo-openclaw-client
```

You can use either command style below.

Host wrapper style:

```bash
./scripts/cli.sh channels add --channel telegram --account <account> --name "<agent-name>" --token "<telegram_bot_token>"
./scripts/cli.sh agents bind --agent <agent-name> --bind telegram:<account>
```

Interactive shell style:

```bash
./scripts/cli-shell.sh
openclaw channels add --channel telegram --account <account> --name "<agent-name>" --token "<telegram_bot_token>"
openclaw agents bind --agent <agent-name> --bind telegram:<account>
```

Example naming:

- `<account>`: `mv-t1`
- `<agent-name>`: `mv-t1-mngr`

### 8.4 Choose Telegram group policy

Open access:

```bash
./scripts/cli.sh config set channels.telegram.groupPolicy '"open"'
./scripts/cli.sh config set channels.telegram.accounts.<account>.groupPolicy '"open"'
```

Restricted access to specific Telegram users:

```bash
./scripts/cli.sh config set channels.telegram.accounts.<account>.groupAllowFrom '["tg:<telegram_user_id>"]'
```

Replace `<telegram_user_id>` with the Telegram user ID you want to allow. This guide does not yet cover how to look up that ID.

### 8.5 Verify the channel and bindings

```bash
./scripts/cli.sh channels list
./scripts/cli.sh agents list --bindings
```

Or from the interactive shell:

```bash
openclaw channels list
openclaw agents list --bindings
```

### 8.6 Restart after channel changes

```bash
./scripts/down.sh
./scripts/up.sh
```

### 8.7 Approve Telegram pairing codes

When Telegram gives you a pairing code, approve it with:

```bash
openclaw pairing approve telegram <pairing_code>
```

## 9) Start/stop later

Start:

```bash
./scripts/up.sh
```

Logs:

```bash
./scripts/logs.sh
```

Stop:

```bash
./scripts/down.sh
```

## 10) Upgrade later

To pull the latest source, rebuild the image, and restart:

```bash
./scripts/upgrade.sh
```

Your config and data are preserved.

## Common issues

### “Docker is installed but not running”

- Open Docker Desktop
- Wait 10 to 30 seconds
- Run `./scripts/setup.sh` again

### Docker CLI talks to the wrong daemon / API version mismatch

If `./scripts/setup.sh` says Docker is not responding but Docker Desktop shows `running`, a common cause is:

- Docker CLI installed via Homebrew
- Docker Desktop daemon running a newer API version

This repo’s scripts try to make this more robust on macOS by setting `DOCKER_API_VERSION=1.44` when it’s not already set.

Troubleshooting:

- Run `docker context use desktop-linux` then `docker info`
- Docker menu → Troubleshoot → Restart Docker Desktop, then wait until it says running
- To inspect daemon logs: `tail -50 ~/Library/Containers/com.docker.docker/Data/log/vm/dockerd.log`
- If it still fails: Docker menu → Troubleshoot → Clean / Purge data, then retry setup

### “permission denied” when accessing files

- Make sure the chosen directories actually exist
- Check Docker Desktop file sharing (step 3)

### Dashboard opens but pairing keeps looping

1. Make sure you opened the full tokenized URL from `./scripts/dashboard.sh`
2. Approve the pending device with `./scripts/cli.sh devices list` and `./scripts/cli.sh devices approve <requestId>`
3. If needed, restart and reopen:

```bash
./scripts/down.sh
./scripts/up.sh
./scripts/dashboard.sh
```

### “gateway token mismatch”

Restart the gateway and reopen the tokenized URL:

```bash
./scripts/down.sh
./scripts/up.sh
./scripts/dashboard.sh
```

If the dashboard has stored an old token, paste the current token from `.env` into Control UI settings.
