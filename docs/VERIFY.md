# Verify the setup (quick checklist)

## 1) Confirm the dashboard exposure

- Open: `http://127.0.0.1:18789/`
- You should need the tokenized URL from:

```bash
./scripts/dashboard.sh
```

You can also check the port binding:

```bash
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

On **Linux** (secure compose), you should see `127.0.0.1:18789->18789/tcp` (not `0.0.0.0:...`).

On **macOS**, this repo uses `docker-compose.macos.yml` which binds to `0.0.0.0` due to a Docker Desktop loopback port-binding quirk. The gateway is still token-authenticated, but treat this as broader network exposure than a strict loopback bind.

## 2) Confirm per-agent workspaces are present and mapped

Your `.env` should define:

- `OPENCLAW_WORKSPACES_DIR=...` (root folder for all agent workspaces)
- `OPENCLAW_WORKSPACE_DIR=...` (single workspace folder used as the default mount)
- provider keys for enabled model backends (`OPENROUTER_API_KEY` and/or `BANKR_API_KEY`)

`OPENCLAW_WORKSPACE_DIR` should normally be a subdirectory inside `OPENCLAW_WORKSPACES_DIR`, usually `<OPENCLAW_WORKSPACES_DIR>/main`.

Example:

- `OPENCLAW_WORKSPACES_DIR=$HOME/OpenClawWorkspaces`
- `OPENCLAW_WORKSPACE_DIR=$HOME/OpenClawWorkspaces/main`

Check host-side directories:

```bash
ls -la "$OPENCLAW_WORKSPACES_DIR"
```

You should see at least:

- `main/`
- `mv-coder/`
- `mv-researcher/`
- `mv-planner/`

Sanity check inside the container:

```bash
./scripts/cli.sh status
```

Linux host-network workaround:

```bash
./scripts/cli.sh status
```

And verify your Compose volumes in `docker-compose.yml` include:

- `${OPENCLAW_CONFIG_DIR}:/home/node/.openclaw`
- `${OPENCLAW_WORKSPACE_DIR}:/home/node/.openclaw/workspace`

## 3) Run OpenClaw’s security audit

```bash
./scripts/security-audit.sh
```

Fix anything the audit flags before you enable external channels.

## 4) Confirm tool sandboxing mode (config)

In this Docker wrapper, the gateway runs inside Docker. OpenClaw tool sandboxing
would require giving the gateway Docker access (e.g. mounting `/var/run/docker.sock`),
which is a major security risk.

So the secure default here is:

- `agents.defaults.sandbox.mode: "off"`

If this repo includes a secure config template (`config/openclaw.secure.json`), the setup script will copy it to `openclaw.json` on first setup (if missing).

## 5) Run simple per-agent identity checks

Test each agent explicitly:

```bash
./scripts/cli.sh agent --agent main --message "State your name in one sentence."
./scripts/cli.sh agent --agent mv-coder --message "State your name in one sentence."
./scripts/cli.sh agent --agent mv-researcher --message "State your name in one sentence."
./scripts/cli.sh agent --agent mv-planner --message "State your name in one sentence."
```

If an agent behaves like first-run onboarding ("Who am I?"), that workspace
still has a `BOOTSTRAP.md`. Remove it (or run setup/upgrade with
`--cleanup-bootstrap`) and restart the gateway.

```bash
./scripts/down.sh && ./scripts/up.sh
```
