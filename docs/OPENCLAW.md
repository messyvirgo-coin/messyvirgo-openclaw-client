# OpenClaw In This Wrapper

This repository is a deployment wrapper around upstream [OpenClaw](https://github.com/openclaw/openclaw). It provides the local templates, compose files, scripts, and defaults used for Messy Virgo deployments.

## Start Here

- [openclaw-secure/docs/INSTALL-docker.md](../openclaw-secure/docs/INSTALL-docker.md) for Docker install
- [openclaw-raw/docs/INSTALL-native.md](../openclaw-raw/docs/INSTALL-native.md) for native install
- [openclaw-secure/docs/VERIFY.md](../openclaw-secure/docs/VERIFY.md) for health checks
- [TELEGRAM.md](TELEGRAM.md) for Telegram setup
- [MEMORY.md](MEMORY.md) for memory defaults and behavior
- [PLUGINS.md](PLUGINS.md) for plugin install and inspection
- [SECURITY.md](SECURITY.md) for the wrapper security model

## What This Repo Owns

- `config/openclaw.json` and `config/openclaw.native.json` for baseline wrapper config
- `config/workspaces/main/` for the default workspace content
- `openclaw-secure/` and `openclaw-raw/` for deployment scripts and compose files

## Configuration Workflow

1. Treat `config/` as templates, not runtime state.
2. `setup.sh` seeds config on first install.
3. `upgrade.sh` preserves deployed config unless you explicitly sync templates.
4. The runtime source of truth is `$OPENCLAW_CONFIG_DIR/openclaw.json` on the host.

## Upstream Reference

- [Gateway](https://docs.openclaw.ai/gateway)
- [CLI](https://docs.openclaw.ai/cli)
- [Channels](https://docs.openclaw.ai/channels)
- [Configuration reference](https://docs.openclaw.ai/gateway/configuration-reference)
- [Telegram channel](https://docs.openclaw.ai/channels/telegram)
