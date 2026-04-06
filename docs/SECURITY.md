## Security / threat model (short & honest)

See [OPENCLAW.md](OPENCLAW.md) for how wrapper docs fit together.

### What this Docker setup protects well

- **Published ports**: the default stack merges **`docker-compose.ports.localhost.yml`**, which maps the gateway (and bridge) to **`127.0.0.1`** on the host. On **Linux**, some setups use **`docker-compose.linux-hostnet.yml`** (`network_mode: host`) instead—see [openclaw-secure/docs/INSTALL-docker.md](../openclaw-secure/docs/INSTALL-docker.md) §5.
- **On macOS (Docker Desktop)**: reachability and how `docker ps` labels ports can differ from Linux; the gateway remains **token-authenticated**.
- **Filesystem access is explicit**: the compose file mounts **config** (`OPENCLAW_CONFIG_DIR` → `~/.openclaw` in-container), **all agent workspaces** (`OPENCLAW_WORKSPACES_DIR`), and the **default workspace** (`OPENCLAW_WORKSPACE_DIR`). You choose those paths in `.env`; they are not your entire `$HOME` unless you set them that way.
- **Gateway container hardening** (see `docker-compose.secure.yml`): read-only rootfs, dropped capabilities, `no-new-privileges`, tmpfs for temp dirs, resource limits.
- **Tool sandboxing in this wrapper**: `agents.defaults.sandbox.mode` is **`off`** in Docker so the gateway does not need the host Docker socket. Nested OpenClaw sandboxes are a separate feature when sandbox mode is enabled elsewhere—see § below.

### What this does NOT perfectly solve

- Docker is **not a perfect security boundary** (kernel/container escapes are theoretically possible).
- If you set the workspace to your real project folder, OpenClaw can of course read/write **everything in that folder**.
- If you enable channels (Telegram/WhatsApp/etc.), input comes from outside → **prompt-injection risk** stays real.

### Note about OpenClaw "tool sandboxing" in this Docker setup

OpenClaw's built-in tool sandboxing uses Docker to spawn sandbox containers **from the Gateway host**.
When the Gateway itself runs inside Docker (this repo), giving it access to Docker (e.g. mounting `/var/run/docker.sock`)
would effectively grant it high-privilege control over your host.

For that reason, this wrapper defaults to **sandboxing = off** and relies on:

- container isolation + hardening (read-only rootfs, dropped caps, no-new-privileges)
- explicit config + workspace mounts (you choose paths in `.env`; avoid pointing the default workspace at a broad home tree)
- localhost-oriented port publishing where the compose overlay uses `127.0.0.1`, plus token auth on all platforms

**Why `sandbox.docker` is omitted from `config/openclaw.json`:** With `agents.defaults.sandbox.mode: "off"`, the nested `sandbox.docker` block is inactive. This wrapper intentionally avoids Docker sandbox spawning from inside the gateway container (it would require Docker socket access and weaken host security). Keeping the block caused confusion and warnings in some versions. If you enable `sandbox.mode` in the future, add a `sandbox.docker` block (image, workdir, caps, network, etc.) — see OpenClaw upstream config for the schema.

### Best practices (recommended)

- Use a **dedicated workspace folder** (e.g. `~/OpenClawWorkspace`) and copy only what you need into it.
- For channels:
  - Keep DMs on pairing/allowlists (avoid “open”).
  - In groups: require mention.
- Run the audit regularly:

```bash
./openclaw-secure/scripts/security-audit.sh
```

### Even safer (harder boundary)

Next step: run OpenClaw in a **dedicated VM** (or a separate machine) and access it via Tailscale.
That’s significantly stronger isolation than containers if you want real OS separation.
