# OpenClaw (AI Assistant) — Messy Virgo wrapper

This repo wraps [OpenClaw](https://github.com/openclaw/openclaw) with shared config, models, agents, and skills. Choose your deployment mode:

| Mode | Path | Use when |
|------|------|----------|
| **Secure-client** (Docker) | `secure-client/` | You want container isolation, hardened runtime |
| **Openclaw-raw** (native) | `openclaw-raw/` | You prefer host install, no Docker |

Both use the same `config/` and `skills/` from the repo root.

This code is provided **as-is** and maintained **best-effort**. PRs/issues are welcome, but this repo is not a support channel (see [SUPPORT.md](./SUPPORT.md)).

## Quickstart

### Secure-client (Docker, Linux + macOS)

- **macOS**: [secure-client/docs/INSTALL-macos.md](secure-client/docs/INSTALL-macos.md)
- **Linux**: [secure-client/docs/INSTALL-linux.md](secure-client/docs/INSTALL-linux.md)

```bash
./secure-client/scripts/setup.sh
./secure-client/scripts/dashboard.sh
```

### Openclaw-raw (native, no Docker)

- **Native**: [openclaw-raw/docs/INSTALL-native.md](openclaw-raw/docs/INSTALL-native.md)

```bash
./openclaw-raw/scripts/setup.sh
./openclaw-raw/scripts/gateway.sh
```

## Secure-client operations

```bash
./secure-client/scripts/up.sh
./secure-client/scripts/down.sh
./secure-client/scripts/logs.sh
./secure-client/scripts/cli.sh status
./secure-client/scripts/cli-shell.sh
```

## Upgrade (secure-client)

Why not use "Update now" in the UI?

- This wrapper runs OpenClaw from a Docker image, so in-app self-update is typically skipped with `reason: "not-git-install"` (runtime path is usually `/app`).
- In container/immutable deployments, the correct update path is: pull the latest OpenClaw source (via `./secure-client/scripts/upgrade.sh`, which updates your clone from `OPENCLAW_GIT_REPO`) → rebuild image → restart container.

If you want to apply updated wrapper config templates (including security defaults) to an existing deployment, run:

```bash
./secure-client/scripts/upgrade.sh
./secure-client/scripts/upgrade.sh --sync-config   # apply updated config templates
```

More: [secure-client/docs/VERIFY.md](secure-client/docs/VERIFY.md) · [docs/PLUGINS.md](docs/PLUGINS.md)

## Agent packs

Pack-specific agents live in a separate repo: `../messyvirgo-openclaw-agents`.

```bash
# 1) Bring up wrapper
./secure-client/scripts/setup.sh
./secure-client/scripts/up.sh

# 2) Install pack
cd ../messyvirgo-openclaw-agents
./scripts/install.sh --target wrapper --profile mv-t1
```

CLI for channel setup: `./secure-client/scripts/cli.sh channels --help`

## Security (secure-client)

- Linux: dashboard ports bound to `127.0.0.1`
- macOS: Docker Desktop quirk uses `0.0.0.0`; gateway is token-authenticated
- Single explicit workspace mount; tool sandboxing off (see [docs/SECURITY.md](docs/SECURITY.md))

## License

Apache-2.0. See [LICENSE](./LICENSE).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).
