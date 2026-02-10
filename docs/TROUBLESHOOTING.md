# Troubleshooting

## Access checks / Bankr / Moltbook in alert

- **Bankr API key invalid or missing**  
  Set `BANKR_API_KEY` in `.env.api-keys` (get a key with **Agent API** access from [bankr.bot/api](https://bankr.bot/api)). Run `./scripts/up.sh` so the key is merged into `.env` and written to `~/.openclaw-secure/clawdbot/skills/bankr/config.json` by `setup-bankr.sh`. See [BANKR-SETUP.md](BANKR-SETUP.md).

- **Moltbook API key missing or access denials**  
  Set `MOLTBOOK_API_KEY` in `.env.api-keys`, then run `./scripts/up.sh`. The key is passed into the gateway. Verify at [Moltbook](https://www.moltbook.com) that the key is valid. See [MOLTBOOK-CREDENTIALS.md](MOLTBOOK-CREDENTIALS.md).

- **MEMORY.md missing (Moltbook scans)**  
  The gateway entrypoint runs `sync-workspace-memory.sh`, which creates or updates workspace `MEMORY.md` (long-term + yesterday + today). If the file was missing, it is created with a minimal placeholder. Ensure the workspace volume is writable and the gateway has started at least once. Path: `$OPENCLAW_WORKSPACE_DIR/MEMORY.md` (e.g. `~/OpenClawWorkspace/MEMORY.md`).

## Scripts: "pipefail" or shell errors

Scripts use `set -eu` and enable `set -o pipefail` only when running under Bash. If a script is invoked with a shell that does not support `pipefail` (e.g. some minimal `sh`), it should no longer fail on that. Ensure scripts are run with `bash` when possible (e.g. `bash ./scripts/foo.sh` or use the script’s shebang `#!/usr/bin/env bash`).

## SIGKILL / access check scripts killed

If access-check or other scripts are terminated with **SIGKILL** (e.g. exit 137), common causes:

1. **Out-of-memory (OOM)** — The kernel or Docker may be killing the process. Check:
   - `dmesg | tail` or system logs for OOM killer messages
   - Docker container memory limits and host RAM
2. **Resource limits** — CPU/memory limits on the container or cgroup.
3. **Timeout** — Some runner (cron, watchdog) may be killing long-running scripts; increase timeouts or run in background.

Adjust Docker resource limits if needed, or run the script outside the container to see if the host has enough resources.
