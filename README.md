# OpenClaw (AI Assistant) — Docker wrapper (Linux + macOS)

This repo is a **wrapper** that runs [OpenClaw](https://github.com/openclaw/openclaw) **fully in Docker** and aims to keep host exposure minimal (single explicit RW workspace mount, hardened containers).

This code is provided **as-is** and maintained **best-effort**. PRs/issues are welcome, but this repo is not a support channel (see [SUPPORT.md](./SUPPORT.md)).

## Quickstart (non-technical)

- **macOS**: follow `[docs/INSTALL-macos.md](docs/INSTALL-macos.md)`
- **Linux**: follow `[docs/INSTALL-linux.md](docs/INSTALL-linux.md)`

## TL;DR (technical)

```bash
./scripts/setup.sh
./scripts/dashboard.sh
```

## Operations (start/stop/logs)

```bash
# Start
./scripts/up.sh

# Stop
./scripts/down.sh

# Logs (follow)
./scripts/logs.sh

# Run OpenClaw CLI commands
./scripts/cli.sh status
./scripts/cli.sh dashboard --no-open

# Interactive CLI shell (run multiple commands)
./scripts/cli-shell.sh
```

## Connect Telegram to an Agent

Channel setup is CLI-driven in OpenClaw. This wrapper now includes a helper that
registers a channel account and binds it to an existing agent in one flow.

```bash
# Interactive token prompt (default channel: telegram)
./scripts/setup-agent-channel.sh --agent messy-funds-mngr

# Non-interactive usage
./scripts/setup-agent-channel.sh --agent messy-funds-mngr --token "$TELEGRAM_BOT_TOKEN"
```

What it does:

- checks gateway health
- runs `./scripts/security-audit.sh` by default (use `--skip-audit` to bypass)
- enables the channel plugin first (`./scripts/cli.sh plugins enable <channel>`)
- validates channel schema before writing config (fails fast with restart guidance if missing)
- runs `./scripts/cli.sh channels add ...`
- runs `./scripts/cli.sh agents bind --agent <id> --bind telegram`
- probes channel status and prints pairing/verification commands

After setup, approve first-time DM pairing:

```bash
./scripts/cli.sh pairing list telegram
./scripts/cli.sh pairing approve telegram <CODE>
```

Then add your Telegram user ID to the allowlist (fixes the "groupPolicy allowlist empty" Doctor warning and allows DMs + group messages from you):

```bash
./scripts/cli.sh config set channels.telegram.allowFrom '["<YOUR_ID>"]' --strict-json
./scripts/cli.sh config set channels.telegram.groupAllowFrom '["<YOUR_ID>"]' --strict-json
./scripts/down.sh && ./scripts/up.sh
```

Replace `<YOUR_ID>` with the numeric ID shown when you DM the bot (e.g. `618041013`).

Verify:

```bash
./scripts/cli.sh agents bindings
```

## Upgrade

```bash
./scripts/upgrade.sh
```

Why not use "Update now" in the UI?

- This wrapper runs OpenClaw from a Docker image, so in-app self-update is typically skipped with `reason: "not-git-install"` (runtime path is usually `/app`).
- In container/immutable deployments, the correct update path is: sync fork -> rebuild image -> restart container via `./scripts/upgrade.sh`.

If you want to apply updated wrapper config templates (including security
defaults) to an existing deployment, run:

```bash
./scripts/upgrade.sh --sync-config
```

More checklists: `[docs/VERIFY.md](docs/VERIFY.md)`

Linux note: if `./scripts/up.sh` fails with a port bind error even though the port is free, use:

```bash
./scripts/up.sh
./scripts/cli.sh health --json
```

## Multi-Agent Setup

This repo ships a pre-configured multi-agent architecture:

- **Messy Virgo** (main) — orchestrator that handles chat and delegates tasks
- **Coder** — code writing and debugging (Kimi K2.5)
- **Researcher** — web search and data lookup (Gemini 2.5 Flash)
- **Planner** — multi-step planning with deep thinking (Kimi K2.5)
- **Messy Funds Manager** — finance/funds operations specialist via shared MCP runtime

Cost-optimization defaults are also pre-applied:

- `temperature: 0.2` on all models for prompt cache efficiency
- 50K token context cap to encourage session resets
- Context pruning (30m TTL, keeps last 3 assistant turns)
- Safeguard compaction (32K token headroom reserved)
- 30m heartbeat using the cheapest available model

See `docs/STRATEGY.md` for details on customizing agents and models.
See `docs/OPTIMIZATION-GUIDE.md` for what's applied and why.
See `docs/MESSY-FUNDS-MNGR-CONFIG.md` for the funds agent's tool permissions, guardrails, and MCP runtime notes.

## Next Step: Install Messy Virgo Platform MCP Server

Install and validate the MCP server before using the `messy-funds-mngr` agent. In this wrapper, MCP runtime registration is instance-level via `config/mcporter.json`, while agent behavior lives in `config/workspaces/**`.

1. **Prerequisites**
   OpenClaw is already running from this repo (`./scripts/up.sh`). You have the
   Messy Virgo Platform MCP endpoint URL and a valid API key/token.

1. **Register the MCP server (wrapper flow)**
   This repo already includes the MCP server entry (`messy-virgo-funds`) in
   `config/mcporter.json`. Set the required runtime values in `.env`:

```bash
# Required by config/mcporter.json
MESSY_VIRGO_MCP_URL="https://api.example.com/mcp"
MESSY_VIRGO_API_KEY="sk_example_123"
```

   If your MCP server runs on your host machine (for example on `localhost:8000`),
   you can still set `MESSY_VIRGO_MCP_URL` with `localhost`. The wrapper rewrites it
   to `host.docker.internal` for container reachability.

   If you are starting fresh, you can copy defaults first:

```bash
cp envs/local.env.example .env
```

1. **Validate and reload**
   Check gateway health and MCP-aware runtime status:

```bash
./scripts/cli.sh health --json
./scripts/cli.sh status
```

   Restart services after changing `.env` so the MCP runtime picks up new values:

```bash
./scripts/down.sh
./scripts/up.sh
```

If your MCP server uses non-Bearer auth, adjust `config/mcporter.json` accordingly (for example by changing auth fields for that server entry).

## Security model (short)

- **Linux (secure compose)**: dashboard ports are bound to `127.0.0.1`.
- **macOS (Docker Desktop)**: due to a Docker Desktop port-binding quirk, this repo uses `docker-compose.macos.yml` which binds `0.0.0.0` for the dashboard ports. The gateway is still **token-authenticated**, but you should treat this as less strict network exposure and use host firewalling if needed.
- OpenClaw can only read/write the workspace folder you choose in `setup.sh`
- Tool execution (shell/read/write/edit) runs in **Docker sandboxes** (per session), **network disabled by default**

More: `[docs/SECURITY.md](docs/SECURITY.md)`

## License

Apache-2.0. See [LICENSE](./LICENSE).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).
