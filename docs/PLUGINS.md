# Plugins

This wrapper runs OpenClaw in Docker. Use the CLI via:

```bash
./scripts/cli.sh <command> <args>
# or interactive:
./scripts/cli-shell.sh
```

## Example: Opik (LLM observability)

[Opik](https://www.comet.com/docs/opik/integrations/openclaw) exports LLM, tool, and agent traces.

### 1. Install

```bash
./scripts/cli.sh plugins install @opik/opik-openclaw
```

### 2. Configure

```bash
./scripts/cli.sh opik configure
```

Validates Opik URL/API key and writes plugin config.

### 3. Restart gateway

```bash
./scripts/down.sh && ./scripts/up.sh
```

Check status: `./scripts/cli.sh opik status`

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
