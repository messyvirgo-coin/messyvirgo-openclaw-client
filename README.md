# OpenClaw (AI Assistant) — Docker wrapper (Linux + macOS)

This repo is a **wrapper** that runs [OpenClaw](https://github.com/openclaw/openclaw) **fully in Docker** and aims to keep host exposure minimal (single explicit RW workspace mount, hardened containers).

This code is provided **as-is** and maintained **best-effort**. PRs/issues are welcome, but this repo is not a support channel (see [SUPPORT.md](./SUPPORT.md)).

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

- **Linux (secure compose)**: dashboard ports are bound to `127.0.0.1`.
- **macOS (Docker Desktop)**: due to a Docker Desktop port-binding quirk, this repo uses `docker-compose.macos.yml` which binds `0.0.0.0` for the dashboard ports. The gateway is still **token-authenticated**, but you should treat this as less strict network exposure and use host firewalling if needed.
- OpenClaw can only read/write the workspace folder you choose in `setup.sh`
- Tool execution (shell/read/write/edit) runs in **Docker sandboxes** (per session), **network disabled by default**

More: `[docs/SECURITY.md](docs/SECURITY.md)`

## License

Apache-2.0. See [LICENSE](./LICENSE).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).
