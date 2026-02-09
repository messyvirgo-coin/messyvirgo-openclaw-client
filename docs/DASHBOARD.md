# Dashboards

## One unified dashboard (recommended)

- **URL:** `http://127.0.0.1:18788/` (or `DASHBOARD_X_PORT` from `.env`)

This single page shows:

1. **Top: Memory — tasks, commitments, directives** — Reads from your **workspace** `memory/YYYY-MM-DD.md` (e.g. `memory/2026-02-09.md`). Use the date dropdown to switch days. This is the canonical task list and status you maintain; the dashboard just displays it. The dashboard container mounts your OpenClaw workspace read-only so it can read `memory/` and (if you add it later) `skills/`. **The agent also receives this memory at the start of each session:** when the gateway starts, today’s `memory/YYYY-MM-DD.md` is merged into workspace `MEMORY.md`: long-term content is kept and a **"## Today (YYYY-MM-DD)"** section is added or updated. So the agent gets one file with both long-term memory and today’s tasks/commitments (on macOS, `MEMORY.md` and `memory.md` are the same file).
2. **Bottom: X Monitor** — Last 5 tweets per account for @MEssyVirgoCoin, @MessyVirgoBot, @MessyVirgoF, @MessyVirgoM. “Refresh tweets” to reload.

**OpenClaw Control UI** (sessions, agents, gateway config) is **not** embedded. Use the link in the dashboard header to open it in a separate tab at `http://127.0.0.1:18789/` when you need it.

The unified dashboard is **fully contained in this repo** (`dashboard-x/`). Updating the OpenClaw repo does not remove or break it.

Start the stack with:

```bash
./scripts/up.sh
```

Then run `./scripts/dashboard.sh` to print both URLs.

### Where to see agent tasks (e.g. MessyClaw-Macro-Scout)

Open **OpenClaw Control UI** from the link in the dashboard header (or go to `http://127.0.0.1:18789/` and use the token from `./scripts/dashboard.sh`). There, use **Sessions** to list agents and sessions and see activity, tool calls, and task state.

---

## Remote access with Tailscale Serve

The dashboards bind to localhost by default. To access them from other devices on your Tailnet:

1. Install [Tailscale](https://tailscale.com) on the same machine that runs Docker.
2. Enable **Tailscale Serve** to proxy a public path to a local port. Example (proxy Control UI only):
   ```bash
   sudo tailscale serve --bg --set-path=/openclaw http://127.0.0.1:18789
   ```
   Then open: `https://<your-tailnet-name>/openclaw` (use the tokenized URL with the same token).
3. To also expose the X Monitor:
   ```bash
   sudo tailscale serve --bg --set-path=/x http://127.0.0.1:18788
   ```
   Then open: `https://<your-tailnet-name>/x`.

**Security:** Tailscale Serve uses TLS and Tailscale auth; only devices on your Tailnet can reach these URLs. Keep `OPENCLAW_GATEWAY_TOKEN` secret and use the token when opening the Control UI.

For more options (e.g. funnel, multiple paths), see [Tailscale Serve](https://tailscale.com/kb/1312/serve).
