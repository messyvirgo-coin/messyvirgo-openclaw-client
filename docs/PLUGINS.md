# Plugins

This wrapper runs OpenClaw in Docker. Use the CLI via:

```bash
./openclaw-secure/scripts/cli.sh <command> <args>
# or interactive:
./openclaw-secure/scripts/cli-shell.sh
```

## Example: Opik (LLM observability)

[Opik](https://www.comet.com/docs/opik/integrations/openclaw) exports LLM, tool, and agent traces.

### 1. Install

```bash
./openclaw-secure/scripts/cli.sh plugins install @opik/opik-openclaw
```

### 2. Configure

```bash
./openclaw-secure/scripts/cli.sh opik configure
```

Validates Opik URL/API key and writes plugin config.

### 3. Restart gateway

```bash
./openclaw-secure/scripts/down.sh && ./openclaw-secure/scripts/up.sh
```

Check status: `./openclaw-secure/scripts/cli.sh opik status`

### 4. Allow plugin

Explicitly allow the plugin so it can load. Add to your config:

```json
"plugins": {
  "allow": ["opik-openclaw"]
}
```

Edit `~/.openclaw-secure/openclaw.json` (or `$OPENCLAW_CONFIG_DIR/openclaw.json`). Merge into the existing `"plugins"` key if it already exists. Restart the gateway afterward.

---

Full setup: [Opik OpenClaw integration](https://www.comet.com/docs/opik/integrations/openclaw).
