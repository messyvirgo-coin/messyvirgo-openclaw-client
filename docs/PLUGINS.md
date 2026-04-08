# Plugins

State lives under `$OPENCLAW_CONFIG_DIR`. Template: [config/openclaw.json](../config/openclaw.json). Upstream: [`openclaw plugins`](https://docs.openclaw.ai/cli/plugins).

## CLI

```bash
./openclaw-secure/scripts/cli.sh plugins list
./openclaw-secure/scripts/cli.sh plugins doctor
# Native: ./openclaw-raw/scripts/cli.sh …
```

## Install

```bash
./openclaw-secure/scripts/cli.sh plugins install <package-or-spec>
```

Restart the gateway afterward. Pin versions in production; treat installs as code execution.

## Config sync

`setup.sh` copies the template once. `upgrade.sh --sync-config` overwrites deployed `openclaw.json` — back up first.
