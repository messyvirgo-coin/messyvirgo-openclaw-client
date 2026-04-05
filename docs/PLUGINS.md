# Plugins (wrapper)

Templates enable first-party plugins (`memory-core`, `telegram`, `tavily`, …). Additional packages install with the OpenClaw CLI and persist under **`OPENCLAW_CONFIG_DIR`**.

- [`openclaw plugins`](https://docs.openclaw.ai/cli/plugins)
- [Plugin system](https://docs.openclaw.ai/tools/plugin)
- [Gateway security](https://docs.openclaw.ai/gateway/security)

## 1) CLI entry points

Docker (same volumes as the gateway):

```bash
./openclaw-secure/scripts/cli.sh plugins --help
./openclaw-secure/scripts/cli-shell.sh
```

Native:

```bash
./openclaw-raw/scripts/cli.sh plugins --help
```

## 2) Install flow

1. List installed:

   ```bash
   ./openclaw-secure/scripts/cli.sh plugins list
   ./openclaw-secure/scripts/cli.sh plugins list --verbose
   ```

2. Install (resolution order: upstream docs / ClawHub / npm):

   ```bash
   ./openclaw-secure/scripts/cli.sh plugins install <package-or-spec>
   ```

   Pin versions in production; plugins run arbitrary code.

3. Configure per plugin (env vars, dedicated CLI, etc.).

4. If policy requires it, allowlist via merged edits to **`$OPENCLAW_CONFIG_DIR/openclaw.json`** ([Gateway security](https://docs.openclaw.ai/gateway/security), `plugins inspect <id>`).

5. Restart: `./openclaw-secure/scripts/down.sh && ./openclaw-secure/scripts/up.sh`

6. Verify: `./openclaw-secure/scripts/cli.sh plugins list --enabled` and `plugins doctor`.

---

## 3) Example: Opik (LLM observability)

[Opik’s OpenClaw integration](https://www.comet.com/docs/opik/integrations/openclaw) publishes traces for LLM, tool, and agent activity.

```bash
./openclaw-secure/scripts/cli.sh plugins install @opik/opik-openclaw
./openclaw-secure/scripts/cli.sh opik configure
```

Allowlist if required, restart gateway, then `./openclaw-secure/scripts/cli.sh opik status`.

## 4) Template vs deployed config

Git: `config/openclaw.json`, `config/openclaw.native.json`. Deployed state: **`$OPENCLAW_CONFIG_DIR/openclaw.json`** (including `plugins.installs`, allowlists). `setup.sh` seeds only when missing. Template refresh: `./openclaw-secure/scripts/upgrade.sh --sync-config` (back up first).

## 5) Troubleshooting

| Command / check | Use |
|-----------------|-----|
| `plugins doctor` | Load errors |
| `plugins inspect <id>` | Capabilities, config |
| `openclaw doctor --fix` | Upstream may require before install |

Telegram: [TELEGRAM.md](TELEGRAM.md). Memory defaults: [MEMORY.md](MEMORY.md).
