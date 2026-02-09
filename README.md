# OpenClaw (AI Assistant) — Secure Docker Setup (Linux + macOS)

This repo is a **wrapper** that runs OpenClaw **fully in Docker** with a **localhost-only** dashboard and **exactly one** host folder mounted read/write (the workspace).

## Quickstart (non-technical)

- **macOS**: follow `[docs/INSTALL-macos.md](docs/INSTALL-macos.md)`
- **Linux**: follow `[docs/INSTALL-linux.md](docs/INSTALL-linux.md)`

## TL;DR (technical)

```bash
./scripts/setup.sh
./scripts/dashboard.sh
```

## Operations (start/stop/logs)

```bash
# Start
./scripts/up.sh

# Stop
./scripts/down.sh

# Logs (follow)
./scripts/logs.sh

# Run OpenClaw CLI commands
./scripts/cli.sh status
./scripts/cli.sh dashboard --no-open

# Interactive CLI shell (run multiple commands)
./scripts/cli-shell.sh
```

More checklists: `[docs/VERIFY.md](docs/VERIFY.md)`

**API keys:** Setup overwrites `.env`. To keep API keys across setup runs (and OpenClaw updates), use [docs/ENV-API-KEYS.md](docs/ENV-API-KEYS.md): copy `env.api-keys.example` to `.env.api-keys`, add your keys there; they are merged into `.env` automatically when you run `./scripts/up.sh`.

Linux note: if `./scripts/up.sh` fails with a port bind error even though the port is free, use:

```bash
./scripts/up.sh
./scripts/cli.sh health --json
```

## Security model (short)

- **One dashboard** at `http://127.0.0.1:18788/`: X Monitor (Messy Virgo tweets) + OpenClaw Control UI (sessions, tasks) in one page. Gateway also at `http://127.0.0.1:18789/`. See [docs/DASHBOARD.md](docs/DASHBOARD.md). Ports: dashboard **18788**, gateway **18789**, bridge **18790**.
- OpenClaw can only read/write the workspace folder you choose in `setup.sh`
- Tool execution (shell/read/write/edit) runs in **Docker sandboxes** (per session), **network disabled by default**

More: `[docs/SECURITY.md](docs/SECURITY.md)`
