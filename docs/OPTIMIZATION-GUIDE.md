# OpenClaw Optimization Reference

Configuration applied in `config/openclaw.models.json` and `config/openclaw.agents.json`.

---

## Model Params: temperature 0.2
**File:** `openclaw.models.json` → `agents.defaults.models[*].params`

Consistent temperature improves prompt cache hit rates. Applied to all three models.

---

## Context Window Cap: 50K tokens
**Field:** `agents.defaults.contextTokens`

Caps the effective context window to encourage session resets and reduce runaway cost.
Use `/compact` or `/new` when approaching the limit.

---

## Context Pruning
**Field:** `agents.defaults.contextPruning`

```json
{ "mode": "cache-ttl", "ttl": "30m", "keepLastAssistants": 3 }
```

Prunes messages older than 30 minutes of inactivity, keeping the last 3 assistant turns.

---

## Compaction: Safeguard Mode
**Field:** `agents.defaults.compaction`

```json
{ "mode": "safeguard", "reserveTokensFloor": 32000 }
```

Reserves 32K tokens headroom to prevent context overflow during compaction.

---

## Heartbeat: 30-Minute Interval
**Field:** `agents.defaults.heartbeat`

```json
{ "every": "30m", "model": "deepinfra/deepseek-ai/DeepSeek-V3.2", "includeReasoning": false }
```

Uses the cheapest model (DeepSeek V3.2) for background heartbeat runs.
Keep `HEARTBEAT.md` minimal — an empty or comment-only file skips the API call entirely.

---

## Thinking: Off by Default
**Field:** `agents.defaults.thinkingDefault`

Global default is `off`. Enable per-task with `/think:high`. The planner agent is spawned
with `thinking:high` by the main agent when needed (see `config/workspaces/main/AGENTS.md`).

---

## Memory: Curated MEMORY.md + Daily Logs
**Workspace convention** (see `config/workspaces/main/SOUL.md`)

- `MEMORY.md` is auto-loaded at every startup — keep it short and curated
- `memory/YYYY-MM-DD.md` is indexed but not auto-loaded; use it for session notes
- Agent searches memory on demand via `memory_search` before claiming ignorance
