# Messy Virgo — OpenClaw wrapper

Wraps [OpenClaw](https://github.com/openclaw/openclaw) with shared `config/` and scripts for the default **Messy Virgo** agent.

| Mode | Directory | When |
|------|-----------|------|
| **Docker** | `openclaw-secure/` | Containers, hardened compose |
| **Native** | `openclaw-raw/` | Host install, no Docker |

**`.env`** at repo root. Templates: [`.env.secure.example`](./.env.secure.example) (Docker), [`.env.raw.example`](./.env.raw.example) (native).

As-is / best-effort. See [SUPPORT.md](./SUPPORT.md).

## Quickstart

**Docker:** [openclaw-secure/docs/INSTALL-docker.md](openclaw-secure/docs/INSTALL-docker.md)

```bash
./openclaw-secure/scripts/setup.sh
./openclaw-secure/scripts/dashboard.sh
```

**Native:** [openclaw-raw/docs/INSTALL-native.md](openclaw-raw/docs/INSTALL-native.md)

```bash
./openclaw-raw/scripts/setup.sh
./openclaw-raw/scripts/gateway.sh
```

## Docker operations

```bash
./openclaw-secure/scripts/up.sh
./openclaw-secure/scripts/down.sh
./openclaw-secure/scripts/logs.sh
./openclaw-secure/scripts/cli.sh status
```

Uninstall: [openclaw-secure/docs/UNINSTALL.md](openclaw-secure/docs/UNINSTALL.md).

## Upgrade (Docker)

```bash
./openclaw-secure/scripts/upgrade.sh
./openclaw-secure/scripts/upgrade.sh --sync-config   # refresh repo config template
```

Upstream uses `v*` tags; set `OPENCLAW_GIT_REF=main` in `.env` to track `main`. In-container Control UI self-update often fails; use `upgrade.sh`.

More: [docs/OPENCLAW.md](docs/OPENCLAW.md), [openclaw-secure/docs/VERIFY.md](openclaw-secure/docs/VERIFY.md).

## Security (Docker)

- Dashboard bound to **127.0.0.1** by default (see [docs/SECURITY.md](docs/SECURITY.md); Linux may use host networking).
- Gateway is **token**-authenticated; tool **sandbox is off** in the container (no Docker socket). Details: [docs/SECURITY.md](docs/SECURITY.md).

## License

Apache-2.0 — [LICENSE](./LICENSE).

## Contributing

[CONTRIBUTING.md](./CONTRIBUTING.md).
