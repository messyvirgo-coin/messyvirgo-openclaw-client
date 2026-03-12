# Linux install (beginner-friendly)

This guide covers the generic OpenClaw Docker wrapper only:

- installing the wrapper
- opening the dashboard
- approving the first browser/device pairing
- running basic smoke checks

Messy Virgo pack install, MCP runtime config, and pack-specific verification belong in the `messyvirgo-openclaw-agents` repo.

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
- `BANKR_API_KEY` if you also enable Bankr models
- `BRAVE_API_KEY` for web search

You can leave other defaults alone for a first install.

## 2) Run one-time setup

From the repo folder:

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
- because `setup.sh` starts the gateway, you can go directly to step 3 without running `./scripts/up.sh`

## 3) Open the dashboard

Print the tokenized dashboard URL:

```bash
./scripts/dashboard.sh
```

Open the full URL that includes `#token=...`.

Notes:

- opening `http://127.0.0.1:18789/` without the token may show `unauthorized`
- on Linux, the dashboard should stay bound to `127.0.0.1`

## 4) Approve the first device pairing

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

If you are using a different browser profile, incognito window, or another device, you may need to approve a new pairing request again.

## 5) Run quick smoke checks

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

If an agent behaves like first-run onboarding, the workspace may still contain a `BOOTSTRAP.md`. Restart after cleanup or rerun setup with the appropriate cleanup option.

## 6) Start/stop later

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

## 7) Upgrade later

To pull the latest source, rebuild the image, and restart:

```bash
./scripts/upgrade.sh
```

Your config and data are preserved.

## Common issues

### “permission denied” / “Cannot connect to the Docker daemon”

Option A (quick fix):

```bash
sudo ./scripts/setup.sh
```

Option B (recommended): add your user to the `docker` group, then log out and back in once:

```bash
sudo usermod -aG docker "$USER"
```

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

### Port already in use (`18789` / `18790`)

You can change these values in `.env`:

- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`

After changing them:

```bash
./scripts/down.sh
./scripts/up.sh
./scripts/dashboard.sh
```
