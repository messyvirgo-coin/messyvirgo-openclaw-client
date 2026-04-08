# Verify (Docker)

1. **Dashboard** — `./openclaw-secure/scripts/dashboard.sh` and open the full URL (`#token=…`). Check bindings: `docker ps` (default compose publishes `127.0.0.1:<port>`; Linux host-network compose may show no mapped ports — still use `127.0.0.1`).

2. **Workspaces** — `OPENCLAW_WORKSPACE_DIR` should be under `OPENCLAW_WORKSPACES_DIR` (usually `…/workspaces/main`). `ls "$OPENCLAW_WORKSPACES_DIR"`.

3. **Audit** — `./openclaw-secure/scripts/security-audit.sh`

4. **Sandbox** — Docker image expects `agents.defaults.sandbox.mode: "off"` (no Docker-in-Docker). `setup.sh` enforces this on deploy.

5. **Agent** — `./openclaw-secure/scripts/cli.sh agent --agent main --message "State your name in one sentence."` If it acts like onboarding, remove `BOOTSTRAP.md` (or `upgrade.sh --cleanup-bootstrap`) and restart.

6. **Memory (optional)** — `./openclaw-secure/scripts/cli.sh memory status --deep` — see [../../docs/MEMORY.md](../../docs/MEMORY.md).

Full install: [INSTALL-docker.md](INSTALL-docker.md).
