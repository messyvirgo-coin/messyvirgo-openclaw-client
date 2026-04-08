# Docs index

Wrapper around [OpenClaw](https://github.com/openclaw/openclaw). Upstream: [docs.openclaw.ai](https://docs.openclaw.ai/).

## Install & verify

- [openclaw-secure/docs/INSTALL-docker.md](../openclaw-secure/docs/INSTALL-docker.md) — Docker
- [openclaw-raw/docs/INSTALL-native.md](../openclaw-raw/docs/INSTALL-native.md) — native
- [openclaw-secure/docs/VERIFY.md](../openclaw-secure/docs/VERIFY.md) — smoke checks

## Topics

- [TELEGRAM.md](TELEGRAM.md) — bot + channel
- [MEMORY.md](MEMORY.md) — memory defaults
- [PLUGINS.md](PLUGINS.md) — plugins CLI
- [SECURITY.md](SECURITY.md) — Docker wrapper model

## Repo layout

- `config/openclaw.json` — template (native scripts patch bind + sandbox after copy)
- `config/workspaces/main/` — default workspace files
- `openclaw-secure/`, `openclaw-raw/` — compose + scripts

Runtime config: `$OPENCLAW_CONFIG_DIR/openclaw.json`. `setup.sh` seeds it; `upgrade.sh` only overwrites with `--sync-config`.
