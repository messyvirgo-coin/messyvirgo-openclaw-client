# Plugins

See [OPENCLAW.md](OPENCLAW.md) for the wrapper doc map.

The templates enable core plugins such as `memory-core`, `telegram`, and `tavily`. Anything you install through the OpenClaw CLI is stored under `$OPENCLAW_CONFIG_DIR`.

- [openclaw plugins](https://docs.openclaw.ai/cli/plugins)
- [Plugin system](https://docs.openclaw.ai/tools/plugin)
- [Gateway security](https://docs.openclaw.ai/gateway/security)

## Use The CLI

Docker:

```bash
./openclaw-secure/scripts/cli.sh plugins --help
./openclaw-secure/scripts/cli.sh plugins list
./openclaw-secure/scripts/cli.sh plugins list --verbose
```

Native:

```bash
./openclaw-raw/scripts/cli.sh plugins --help
./openclaw-raw/scripts/cli.sh plugins list
```

## Install A Plugin

1. Check what is already installed.
2. Install the plugin or bundle.
3. Configure it with the plugin's own settings or env vars.
4. Allowlist it in `$OPENCLAW_CONFIG_DIR/openclaw.json` if your policy requires that.
5. Restart the gateway.
6. Verify with `plugins list --enabled` and `plugins doctor`.

```bash
./openclaw-secure/scripts/cli.sh plugins install <package-or-spec>
./openclaw-secure/scripts/down.sh
./openclaw-secure/scripts/up.sh
./openclaw-secure/scripts/cli.sh plugins list --enabled
./openclaw-secure/scripts/cli.sh plugins doctor
```

Notes:

- Pin versions in production.
- Treat plugin installs as code execution.
- Use `plugins inspect <id>` to see capabilities and config.

## Config Location

- Templates: `config/openclaw.json`, `config/openclaw.native.json`
- Runtime state: `$OPENCLAW_CONFIG_DIR/openclaw.json`
- `setup.sh` seeds config on first install.
- `upgrade.sh --sync-config` refreshes templates, so back up first.

## Example

For plugin-specific setup, follow the plugin's own docs after installation. For example, the Opik integration can be installed and configured with:

```bash
./openclaw-secure/scripts/cli.sh plugins install @opik/opik-openclaw
./openclaw-secure/scripts/cli.sh opik configure
./openclaw-secure/scripts/cli.sh opik status
```

## Troubleshooting

- `plugins doctor` for load errors
- `plugins inspect <id>` for capabilities and config
- `openclaw doctor --fix` if the gateway asks for a repair step first
