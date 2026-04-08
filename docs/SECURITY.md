# Security (Docker wrapper)

## What this stack does

- Binds the gateway to **127.0.0.1** on the host by default (Linux host-network mode: see compose + [INSTALL-docker.md](../openclaw-secure/docs/INSTALL-docker.md)).
- Mounts only configured config + workspace paths (not your whole home unless you set it that way).
- Secure overlay: read-only root where applicable, dropped caps, `no-new-privileges`, limits, tmpfs for temp (see compose files).
- **Tool sandbox off** in the gateway container so it does not need the host Docker socket.

## What it does not do

- Container escape and workspace trust are still your responsibility.
- External channels (e.g. Telegram) carry usual prompt-injection risk.

## Baseline

- Dedicated workspace directory; tight DM/group allowlists; mentions in groups unless you trust everyone.
- No secrets in git. Run `./openclaw-secure/scripts/security-audit.sh` after changes.

Stronger isolation: separate VM or machine + remote gateway.
