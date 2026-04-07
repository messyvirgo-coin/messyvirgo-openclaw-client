# Verify the setup (quick checklist)

## 1) Confirm the dashboard exposure

- Open: `http://127.0.0.1:18789/`
- You should need the tokenized URL from:

```bash
./openclaw-secure/scripts/dashboard.sh
```

You can also check the port binding:

```bash
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

With the default **`docker-compose.ports.localhost.yml`** overlay, published ports target **`127.0.0.1`**. In `docker ps`, Linux often shows `127.0.0.1:18789->18789/tcp`.

On **Linux**, if **`docker-compose.linux-hostnet.yml`** is used, the gateway uses **`network_mode: host`**; `docker ps` may list **no** port mapping—use the tokenized URL on `http://127.0.0.1:<OPENCLAW_GATEWAY_PORT>/` anyway.

On **macOS** (Docker Desktop), port display and reachability can differ from Linux; the gateway remains **token-authenticated**. See [INSTALL-docker.md](INSTALL-docker.md) §5.

## 2) Confirm per-agent workspaces are present and mapped

Your `.env` should define:

- `OPENCLAW_WORKSPACES_DIR=...` (root folder for all agent workspaces)
- `OPENCLAW_WORKSPACE_DIR=...` (single workspace folder used as the default mount)
- provider keys for enabled model backends (`OPENROUTER_API_KEY` for chat and memory embeddings, `TAVILY_API_KEY` if using the Tavily plugin, etc.)

`OPENCLAW_WORKSPACE_DIR` should normally be a subdirectory inside `OPENCLAW_WORKSPACES_DIR`, usually `<OPENCLAW_WORKSPACES_DIR>/main`.

Example:

- `OPENCLAW_WORKSPACES_DIR=$HOME/.openclaw/workspaces`
- `OPENCLAW_WORKSPACE_DIR=$HOME/.openclaw/workspaces/main`

Check host-side directories:

```bash
ls -la "$OPENCLAW_WORKSPACES_DIR"
```

You should see at least:

- `main/`

Sanity check (CLI container shares config + workspaces with the gateway):

```bash
./openclaw-secure/scripts/cli.sh status
```

Verify `openclaw-secure/docker-compose.yml` mounts at least:

- `${OPENCLAW_CONFIG_DIR}:/home/node/.openclaw`
- `${OPENCLAW_WORKSPACES_DIR}:/home/node/.openclaw/workspaces`
- `${OPENCLAW_WORKSPACE_DIR}:/home/node/.openclaw/workspace` (default agent workspace)

## 3) Run OpenClaw’s security audit

```bash
./openclaw-secure/scripts/security-audit.sh
```

Fix anything the audit flags before you enable external channels.

## 4) Confirm tool sandboxing mode (config)

In this Docker wrapper, the gateway runs inside Docker. OpenClaw tool sandboxing
would require giving the gateway Docker access (e.g. mounting `/var/run/docker.sock`),
which is a major security risk.

So the secure default here is:

- `agents.defaults.sandbox.mode: "off"`

The setup script copies `config/openclaw.json` (Docker) to the config dir on first setup (if missing). Native mode uses `config/openclaw.native.json`.

## 5) Run simple per-agent identity checks

Test the default agent explicitly:

```bash
./openclaw-secure/scripts/cli.sh agent --agent main --message "State your name in one sentence."
```

If an agent behaves like first-run onboarding ("Who am I?"), that workspace
still has a `BOOTSTRAP.md`. Remove it (or run setup/upgrade with
`--cleanup-bootstrap`) and restart the gateway.

```bash
./openclaw-secure/scripts/down.sh && ./openclaw-secure/scripts/up.sh
```

## 6) Verify semantic memory (optional)

The wrapper uses OpenClaw’s **builtin** memory engine with **OpenRouter** for embeddings. Full architecture, env vars, and CLI commands are in **[../../docs/MEMORY.md](../../docs/MEMORY.md)**.

Quick probe (ephemeral `openclaw-cli` service — same config/workspace mounts as the gateway):

```bash
./openclaw-secure/scripts/cli.sh memory status --deep
```

Alternative: `docker compose … exec openclaw-gateway sh -lc 'openclaw memory status --deep'` if your image exposes the `openclaw` CLI on PATH inside the gateway container.
