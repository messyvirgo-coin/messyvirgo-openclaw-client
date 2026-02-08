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

Linux note: if `./scripts/up.sh` fails with a port bind error even though the port is free, use:

```bash
./scripts/up.sh
./scripts/cli.sh health --json
```

## Security model (short)

- Dashboard is **local-only**: `http://127.0.0.1:18789/` (OpenClaw standard ports: gateway **18789**, bridge **18790** — same on Linux and macOS)
- OpenClaw can only read/write the workspace folder you choose in `setup.sh`
- Tool execution (shell/read/write/edit) runs in **Docker sandboxes** (per session), **network disabled by default**

More: `[docs/SECURITY.md](docs/SECURITY.md)`
