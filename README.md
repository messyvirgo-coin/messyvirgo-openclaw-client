# OpenClaw (AI Assistant) — Messy Virgo wrapper

This repo wraps [OpenClaw](https://github.com/openclaw/openclaw) with shared config, models, agents, and skills. Choose your deployment mode:

| Mode | Path | Use when |
|------|------|----------|
| **OpenClaw-secure** (Docker) | `openclaw-secure/` | You want container isolation, hardened runtime |
| **Openclaw-raw** (native) | `openclaw-raw/` | You prefer host install, no Docker |

Both use the same `config/` and `skills/` from the repo root.

**Environment:** one active file, **`.env`** at the repo root. Copy a template first: **[`.env.secure.example`](./.env.secure.example)** (Docker / openclaw-secure) or **[`.env.raw.example`](./.env.raw.example)** (native / openclaw-raw).

This code is provided **as-is** and maintained **best-effort**. PRs/issues are welcome, but this repo is not a support channel (see [SUPPORT.md](./SUPPORT.md)).

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

Remove the stack and optional data: [openclaw-secure/docs/UNINSTALL.md](openclaw-secure/docs/UNINSTALL.md).

## Upgrade (openclaw-secure)

**Same idea as “Update” / stable channel:** upstream [openclaw/openclaw](https://github.com/openclaw/openclaw) documents **stable** as tagged releases (npm `openclaw@latest`, CLI `openclaw update --channel stable`). This wrapper does **not** use npm inside the image for that; instead **`./openclaw-secure/scripts/upgrade.sh`** fetches [`OPENCLAW_GIT_REPO`](https://github.com/openclaw/openclaw) and checks out the **latest `v*` release tag**, then rebuilds your local Docker image. **You do not set any extra git variables** for that—leave **`OPENCLAW_GIT_REF` unset** in `.env`.

Why not use “Update now” in the Control UI?

- The gateway runs from `/app` in a container, so in-app self-update often reports something like `not-git-install`. Rebuild + restart via **`upgrade.sh`** is the supported path for this layout.

**Optional (not stable):** set **`OPENCLAW_GIT_REF=main`** only if you intentionally want the moving **`main`** branch (closer to npm `dev` / pre-release features). That is **not** the same as stable.

If you want to apply updated **wrapper** config templates to an existing deployment:

```bash
./openclaw-secure/scripts/upgrade.sh
./openclaw-secure/scripts/upgrade.sh --sync-config   # apply updated config templates
```

More: [openclaw-secure/docs/VERIFY.md](openclaw-secure/docs/VERIFY.md) · [docs/MEMORY.md](docs/MEMORY.md) · [docs/PLUGINS.md](docs/PLUGINS.md) · [docs/TELEGRAM.md](docs/TELEGRAM.md)

## Agent packs

Pack-specific agents live in a separate repo: `../messyvirgo-openclaw-agents`.

```bash
# 1) Bring up wrapper
./openclaw-secure/scripts/setup.sh
./openclaw-secure/scripts/up.sh

# 2) Install pack
cd ../messyvirgo-openclaw-agents
./scripts/install.sh --target wrapper --profile mv-t1
```

CLI for channel setup: `./openclaw-secure/scripts/cli.sh channels --help`

## Security (openclaw-secure)

- Default compose publishes the dashboard on **`127.0.0.1`**; Linux may use **host networking** instead (see [docs/SECURITY.md](docs/SECURITY.md))
- Gateway is **token-authenticated**; explicit config + workspace mounts only
- Tool sandboxing **off** in Docker by default (no Docker socket in the gateway); see [docs/SECURITY.md](docs/SECURITY.md)

## License

Apache-2.0. See [LICENSE](./LICENSE).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).
