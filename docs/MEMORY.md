# Memory

Builtin SQLite memory + OpenRouter embeddings (see [config/openclaw.json](../config/openclaw.json)). Upstream: [memory](https://docs.openclaw.ai/concepts/memory), [memory-config](https://docs.openclaw.ai/reference/memory-config), [`openclaw memory`](https://docs.openclaw.ai/cli/memory).

## Defaults (this repo)

- Embeddings: OpenRouter, `openai/text-embedding-3-small`
- Index: `~/.openclaw/memory/{agentId}.sqlite` (on Docker, under mounted config dir)
- Workspace: `MEMORY.md`, `memory/YYYY-MM-DD.md`
- Dreaming: via `memory-core` plugin in template

Changing embedding provider/model usually needs `memory index --force` for that agent.

## Env

`OPENROUTER_API_KEY`, `OPENCLAW_CONFIG_DIR`, `OPENCLAW_WORKSPACES_DIR` (see `.env` templates).

## CLI (Docker example; native: `openclaw-raw/scripts/cli.sh`)

```bash
./openclaw-secure/scripts/cli.sh memory status --deep
./openclaw-secure/scripts/cli.sh memory search "phrase" --agent main
./openclaw-secure/scripts/cli.sh memory index --force --agent main
```

## Troubleshooting

- `unknown command 'memory'` — CLI/gateway version mismatch
- Empty search — not indexed yet or wrong workspace
- Wrong provider — check `OPENROUTER_API_KEY` and `memorySearch.remote` in deployed config
