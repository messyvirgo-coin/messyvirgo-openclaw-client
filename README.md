# OpenClaw (AI Assistant) — Messy Virgo wrapper

This repo wraps [OpenClaw](https://github.com/openclaw/openclaw) with shared config and models for the default **Messy Virgo** agent. Choose your deployment mode:

| Mode | Path | Use when |
|------|------|----------|
| **OpenClaw-secure** (Docker) | `openclaw-secure/` | You want container isolation, hardened runtime |
| **Openclaw-raw** (native) | `openclaw-raw/` | You prefer host install, no Docker |

Both use the same `config/` from the repo root.

Environment file: **`.env`** at the repo root. Templates: **[`.env.secure.example`](./.env.secure.example)** (Docker), **[`.env.raw.example`](./.env.raw.example)** (native).

Provided as-is, best-effort maintenance. See [SUPPORT.md](./SUPPORT.md).

## Quickstart

### OpenClaw-secure (Docker, Linux + macOS)

- **Install**: [openclaw-secure/docs/INSTALL-docker.md](openclaw-secure/docs/INSTALL-docker.md)

```bash
./openclaw-secure/scripts/setup.sh
./openclaw-secure/scripts/dashboard.sh
```

### Openclaw-raw (native, no Docker)

- **Native**: [openclaw-raw/docs/INSTALL-native.md](openclaw-raw/docs/INSTALL-native.md)

```bash
./openclaw-raw/scripts/setup.sh
./openclaw-raw/scripts/gateway.sh
```

## OpenClaw-secure operations

```bash
./openclaw-secure/scripts/up.sh
./openclaw-secure/scripts/down.sh
./openclaw-secure/scripts/logs.sh
./openclaw-secure/scripts/cli.sh status
./openclaw-secure/scripts/cli-shell.sh
```

Uninstall: [openclaw-secure/docs/UNINSTALL.md](openclaw-secure/docs/UNINSTALL.md).

## Upgrade (openclaw-secure)

Upstream [stable](https://github.com/openclaw/openclaw) is published as **`v*`** tags. **`setup.sh`** and **`upgrade.sh`** fetch **`OPENCLAW_GIT_REPO`**, check out the latest **`v*`** tag when **`OPENCLAW_GIT_REF`** is unset, and rebuild the image. In-container Control UI self-update is usually unavailable (`not-git-install`); use **`upgrade.sh`** instead.

Set **`OPENCLAW_GIT_REF=main`** in `.env` to track the moving default branch instead of the latest tag.

```bash
./openclaw-secure/scripts/upgrade.sh
./openclaw-secure/scripts/upgrade.sh --sync-config
```

OpenClaw overview (wrapper + links): [docs/OPENCLAW.md](docs/OPENCLAW.md). Verify: [openclaw-secure/docs/VERIFY.md](openclaw-secure/docs/VERIFY.md).

Channels: `./openclaw-secure/scripts/cli.sh channels --help`

## Security (openclaw-secure)

- Default compose publishes the dashboard on **`127.0.0.1`**; Linux may use **host networking** instead (see [docs/SECURITY.md](docs/SECURITY.md))
- Gateway is **token-authenticated**; explicit config + workspace mounts only
- Tool sandboxing **off** in Docker by default (no Docker socket in the gateway); see [docs/SECURITY.md](docs/SECURITY.md)

## License

Apache-2.0. See [LICENSE](./LICENSE).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).
