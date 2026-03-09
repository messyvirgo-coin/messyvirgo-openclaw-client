# Messy Funds Manager Config

This document is the operator-facing reference for the `messy-funds-mngr` agent.

Keep `README.md` as the repo entry point and link here for agent-specific behavior, permissions, and MCP runtime notes.

## Current Tool Policy

The agent uses an explicit allowlist in `config/openclaw.json`.

### Allowed

| Tool | Why it is enabled |
| --- | --- |
| `read`, `write`, `edit`, `apply_patch` | Maintain workspace notes, reports, and small helper scripts |
| `exec`, `process` | Run local checks, create and execute Python helpers, and access the shared MCP runtime via `mcporter` |
| `browser` | Search and navigate web pages when static fetch is not enough |
| `cron` | Schedule recurring fund checks, reviews, and reminders |
| `session_status`, `sessions_list`, `sessions_history`, `sessions_send`, `sessions_spawn` | Coordinate with allowed sub-agents |
| `web_search`, `web_fetch` | Research and retrieve web content |
| `memory_search`, `memory_get` | Reuse prior context and operating memory |

### Intentionally Blocked

| Tool | Why it is blocked |
| --- | --- |
| `bash` | Not needed when `exec` is available |
| `canvas` | No presentation/UI need for this agent |
| `gateway` | Agent should not restart or reconfigure the gateway |
| `image` | Not required for current funds workflow |
| `message` | Telegram is the user channel; the agent should not get broad outbound messaging powers |
| `nodes` | No device, camera, screen, or host-node control needed |

## Guardrails

- Treat browser access as research/navigation, not account automation.
- Do not log into third-party sites or submit forms without explicit approval.
- Use cron for monitoring and scheduled reviews, not for silent irreversible actions.
- Keep writes inside the agent workspace unless the user explicitly re-scopes the task.
- Do not read secrets or unrelated files such as `.env`, SSH keys, wallet files, browser profiles, or cloud credentials unless the user explicitly asks.
- Confirm before irreversible or external side-effect operations unless the user has already approved that class of action.

## MCP Runtime

This repo currently registers the Messy Virgo funds runtime in `config/mcporter.json` as `messy-virgo-funds`.

Right now the agent reaches that runtime through local execution tooling:

```bash
mcporter list messy-virgo-funds
```

That means the required capability today is `exec` rather than a broad "all MCP tools" permission.

If you later register first-class MCP/plugin tools in OpenClaw, review them tool-by-tool and add only the specific ones the agent needs.

## When To Revisit

Revisit this policy if any of these change:

- the agent needs to send messages directly
- the agent needs image analysis
- a new MCP/plugin server is added
- cron jobs are meant to trigger real financial actions
- the workspace mount becomes broader than the dedicated funds workspace
