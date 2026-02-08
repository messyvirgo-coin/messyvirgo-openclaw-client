# Verify the setup (quick checklist)

## 1) Confirm the dashboard is localhost-only

- Open: `http://127.0.0.1:18789/`
- You should need the tokenized URL from:

```bash
./scripts/dashboard.sh
```

On Linux/macOS, you can also check the port binding:

```bash
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

You should see `127.0.0.1:18789->18789/tcp` (not `0.0.0.0:...`).

## 2) Confirm the workspace mount is the only RW host path

Your `.env` defines the only RW host mount:

- `OPENCLAW_WORKSPACE_DIR=...`

Sanity check inside the container:

```bash
./scripts/cli.sh status
```

Linux host-network workaround:

```bash
./scripts/cli.sh status
```

And verify your Compose volumes in `docker-compose.yml` only mount:

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

This wrapper copies `[config/openclaw.secure.json](../config/openclaw.secure.json)` to `openclaw.json` on first setup (if missing).

## 5) Run a simple agent message (local test)

```bash
./scripts/cli.sh agent --session-id localtest --message "Say hello and tell me which workspace folder you can access."
```
