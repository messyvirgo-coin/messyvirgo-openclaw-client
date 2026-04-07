# Memory

See [OPENCLAW.md](OPENCLAW.md) for the wrapper doc map.

This repo uses OpenClaw's built-in SQLite memory engine with wrapper defaults for embeddings, paths, and plugin setup.

- [Memory overview](https://docs.openclaw.ai/concepts/memory)
- [Builtin memory engine](https://docs.openclaw.ai/concepts/memory-builtin)
- [Memory search](https://docs.openclaw.ai/concepts/memory-search)
- [Memory configuration reference](https://docs.openclaw.ai/reference/memory-config)
- [Dreaming](https://docs.openclaw.ai/concepts/dreaming)
- [`openclaw memory` CLI](https://docs.openclaw.ai/cli/memory)

## Defaults

- Embeddings: OpenRouter with `openai/text-embedding-3-small`
- Engine: builtin SQLite + FTS5 + vectors
- Fallback: `none`
- Workspace files: `MEMORY.md` and `memory/YYYY-MM-DD.md`
- Dreaming: enabled through `memory-core` config

## How Memory Is Stored

- `MEMORY.md` holds durable long-term notes.
- `memory/YYYY-MM-DD.md` holds daily notes and working context.
- The built-in index stores one SQLite file per agent at `~/.openclaw/memory/{agentId}.sqlite`.
- In Docker, `~/.openclaw` maps to the host `OPENCLAW_CONFIG_DIR`.

## Config In This Repo

- `config/openclaw.json`: Docker template
- `config/openclaw.native.json`: native template

Key settings to know:

- `memory.citations: "auto"`
- `agents.defaults.memorySearch.provider` and `model`
- `agents.defaults.memorySearch.remote.baseUrl`
- `agents.defaults.memorySearch.remote.apiKey`
- `agents.defaults.memorySearch.store.path`
- `agents.defaults.memorySearch.query.hybrid`
- `agents.defaults.memorySearch.cache.enabled`
- `plugins.entries.memory-core.config.dreaming.enabled`

Changing the embedding provider or model usually requires a full reindex.

## Environment Variables

- `OPENROUTER_API_KEY`: embeddings and chat
- `TAVILY_API_KEY`: Tavily plugin
- `OPENCLAW_CONFIG_DIR`: host config and memory index storage
- `OPENCLAW_WORKSPACES_DIR`: workspace root for agent files

## Deploying Changes

- Docker: `setup.sh` seeds templates on first install, and `upgrade.sh --sync-config` refreshes templates.
- Native: use `openclaw-raw/scripts/setup.sh` and the same sync flag when you want to refresh config.

If you change embeddings or indexing settings, rebuild the index after the deploy.

## Verification

```bash
./openclaw-secure/scripts/cli.sh memory status --deep
./openclaw-secure/scripts/cli.sh memory status --deep --agent main
./openclaw-secure/scripts/cli.sh memory search "your phrase" --agent main
./openclaw-secure/scripts/cli.sh memory index --force --agent main
```

Helpful checks:

- `memory status --deep` for provider and index health
- `memory search "<phrase>" --agent <id>` for retrieval
- `memory index --force --agent <id>` after a provider or model change

## Multi-Agent Notes

Each agent gets its own index file. Use `--agent <id>` to inspect or rebuild a specific agent's memory.

## Troubleshooting

- `unknown command 'memory'` usually means a CLI/gateway version mismatch.
- Empty results usually mean the workspace has not been indexed yet.
- Wrong provider usually means `OPENROUTER_API_KEY`, `remote.baseUrl`, or egress is missing.
- Unexpected `MEMORY.md` edits usually come from dreaming.

Keep this file aligned with `config/openclaw.json` and `config/openclaw.native.json`.
