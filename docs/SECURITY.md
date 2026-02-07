## Security / threat model (short & honest)

### What this Docker setup protects well

- **Dashboard is local-only**: ports are bound to `127.0.0.1`.
  - Not reachable from other devices on your network (unless you forward it yourself).
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
