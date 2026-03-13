## Security / threat model (short & honest)

### What this Docker setup protects well

- **On Linux (secure compose)**: dashboard ports are bound to `127.0.0.1`.
  - Not reachable from other devices on your network (unless you forward it yourself).
- **On macOS (Docker Desktop)**: this repo uses `docker-compose.macos.yml` which binds ports to `0.0.0.0` due to a Docker Desktop loopback port-binding quirk.
  - The gateway is still **token-authenticated**, but network exposure is broader than a strict `127.0.0.1` bind.
- **Filesystem access is limited**: OpenClaw gets **exactly one** host directory as a mount (the workspace), which you choose deliberately.
  - No access to your entire `$HOME`, fewer accidental secrets.
- **Tool sandboxing**: shell/read/write/edit runs (per session) in Docker sandboxes with:
  - `readOnlyRoot: true`
  - `capDrop: ALL`
  - **no network by default** (`network: none`)
  - CPU/RAM/PIDs limits

### What this does NOT perfectly solve

- Docker is **not a perfect security boundary** (kernel/container escapes are theoretically possible).
- If you set the workspace to your real project folder, OpenClaw can of course read/write **everything in that folder**.
- If you enable channels (Telegram/WhatsApp/etc.), input comes from outside → **prompt-injection risk** stays real.

### Note about OpenClaw \"tool sandboxing\" in this Docker setup

OpenClaw's built-in tool sandboxing uses Docker to spawn sandbox containers **from the Gateway host**.
When the Gateway itself runs inside Docker (this repo), giving it access to Docker (e.g. mounting `/var/run/docker.sock`)
would effectively grant it high-privilege control over your host.

For that reason, this wrapper defaults to **sandboxing = off** and relies on:

- container isolation + hardening (read-only rootfs, dropped caps, no-new-privileges)
- a single, explicit RW workspace mount
- localhost-only dashboard exposure where possible (Linux secure compose), and token-authenticated exposure on macOS as noted above

**Why `sandbox.docker` is omitted from `config/openclaw.json`:** With `agents.defaults.sandbox.mode: "off"`, the nested `sandbox.docker` block is inactive. This wrapper intentionally avoids Docker sandbox spawning from inside the gateway container (it would require Docker socket access and weaken host security). Keeping the block caused confusion and warnings in some versions. If you enable `sandbox.mode` in the future, add a `sandbox.docker` block (image, workdir, caps, network, etc.) — see OpenClaw upstream config for the schema.

### Best practices (recommended)

- Use a **dedicated workspace folder** (e.g. `~/OpenClawWorkspace`) and copy only what you need into it.
- For channels:
  - Keep DMs on pairing/allowlists (avoid “open”).
  - In groups: require mention.
- Run the audit regularly:

```bash
./scripts/security-audit.sh
```

### Even safer (harder boundary)

Next step: run OpenClaw in a **dedicated VM** (or a separate machine) and access it via Tailscale.
That’s significantly stronger isolation than containers if you want real OS separation.
