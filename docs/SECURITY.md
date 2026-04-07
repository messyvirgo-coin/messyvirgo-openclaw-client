# Security

See [OPENCLAW.md](OPENCLAW.md) for the wrapper doc map.

## What The Docker Wrapper Protects

- The default stack publishes the gateway on `127.0.0.1` on the host.
- The gateway container uses explicit config and workspace mounts, not your whole home directory unless you point it there.
- The secure compose overlay hardens the container with a read-only root filesystem, dropped capabilities, `no-new-privileges`, tmpfs for temp files, and resource limits.
- Docker sandboxing is disabled in this wrapper, so the gateway does not need host Docker socket access.

## What It Does Not Solve

- Docker is not a perfect security boundary.
- A workspace path still gives OpenClaw access to everything inside that workspace.
- External channels still carry prompt-injection risk.

## Recommended Baseline

- Use a dedicated workspace folder, not a broad home directory.
- Prefer DM pairing and allowlists over open access.
- Require mentions in groups unless you have a specific reason not to.
- Keep bot tokens and config secrets out of git.

## Audit

Run the security audit after deployment or when you change the stack:

```bash
./openclaw-secure/scripts/security-audit.sh
```

## Stronger Isolation

If you need a harder boundary than containers, run OpenClaw in a separate VM or machine and access it remotely.
