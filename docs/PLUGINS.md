# Third-party OpenClaw plugins (wrapper)

This repo ships a baseline `openclaw.json` with a few **built-in / first-party** plugin entries (`memory-core`, `telegram`, `tavily`, and similar). **Third-party** plugins are extra packages (npm, ClawHub, local path, or marketplace) installed through the OpenClaw CLI and recorded under your **deployed** config directory.

Official references:

- [`openclaw plugins` CLI](https://docs.openclaw.ai/cli/plugins)
- [Plugin system](https://docs.openclaw.ai/tools/plugin)
- [Gateway security](https://docs.openclaw.ai/gateway/security) (allowlists, treat installs as running code)

---

## 1) Run the CLI in the right place

**Docker (OpenClaw-secure)** — run commands through the wrapper so they execute in the `openclaw-cli` container with the same volumes as the gateway:

```bash
./openclaw-secure/scripts/cli.sh plugins --help
./openclaw-secure/scripts/cli-shell.sh   # then: openclaw plugins …
```

**Native (openclaw-raw)**:

```bash
./openclaw-raw/scripts/cli.sh plugins --help
```

The gateway must be able to load what you install. Installs and plugin state live under your **`OPENCLAW_CONFIG_DIR`** (Docker default is often `~/.openclaw-secure` on the host, mounted to `/home/node/.openclaw` in the container).

---

## 2) Typical install flow

1. **Discover** what is already present:

   ```bash
   ./openclaw-secure/scripts/cli.sh plugins list
   ./openclaw-secure/scripts/cli.sh plugins list --verbose
   ```

2. **Install** a package (bare names resolve via ClawHub first, then npm — see upstream docs):

   ```bash
   ./openclaw-secure/scripts/cli.sh plugins install <package-or-spec>
   ```

   Prefer **pinned** versions in production (`@scope/pkg@1.2.3` or `--pin` where supported). Plugin installs execute third-party code; only install from sources you trust.

3. **Configure** if the plugin ships a dedicated CLI command or needs env vars — follow that plugin’s README (example below).

4. **Allow** the plugin if your gateway policy requires an explicit allowlist. Merge into the existing `"plugins"` object in **`$OPENCLAW_CONFIG_DIR/openclaw.json`** (do not replace the whole file blindly). The exact key is defined by OpenClaw’s plugin security model — see [Gateway security](https://docs.openclaw.ai/gateway/security) and `plugins inspect <id>` output.

5. **Restart** the gateway so it loads the new extension:

   ```bash
   ./openclaw-secure/scripts/down.sh && ./openclaw-secure/scripts/up.sh
   ```

6. **Verify**:

   ```bash
   ./openclaw-secure/scripts/cli.sh plugins list --enabled
   ./openclaw-secure/scripts/cli.sh plugins doctor
   ```

---

## 3) Example: Opik (LLM observability)

[Opik’s OpenClaw integration](https://www.comet.com/docs/opik/integrations/openclaw) publishes traces for LLM, tool, and agent activity.

```bash
./openclaw-secure/scripts/cli.sh plugins install @opik/opik-openclaw
./openclaw-secure/scripts/cli.sh opik configure
```

Add the plugin to your allow configuration if required, then restart the gateway (`down.sh` / `up.sh`). Check status with:

```bash
./openclaw-secure/scripts/cli.sh opik status
```

---

## 4) Wrapper template vs deployed config

- **In git:** `config/openclaw.json` and `config/openclaw.native.json` are templates.
- **On disk:** `setup.sh` copies the template only when `openclaw.json` is missing. Ongoing plugin entries, `plugins.installs`, and allowlists live in **`$OPENCLAW_CONFIG_DIR/openclaw.json`**.

To refresh the template from the repo without losing plugin state, use `./openclaw-secure/scripts/upgrade.sh --sync-config` only when you understand the merge implications (backups are recommended).

---

## 5) Troubleshooting

- **`plugins doctor`** — reports load errors and manifest issues.
- **`plugins inspect <id>`** — shows capabilities, hooks, and config hints.
- **Invalid config** — upstream may require `openclaw doctor --fix` before install; see CLI messages.
- **Native vs Docker** — use the **same** `OPENCLAW_CONFIG_DIR` mentally: native paths are on the host; Docker paths are host directories bind-mounted into the container.

For channel-specific setup (Telegram, etc.), see [TELEGRAM.md](TELEGRAM.md). For semantic memory built into this wrapper’s template, see [MEMORY.md](MEMORY.md).
