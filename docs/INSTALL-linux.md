## Linux install (beginner-friendly)

### 0) Requirements

- Docker Engine + Docker Compose v2 (`docker compose` must work)
- Optional but recommended: your user is in the `docker` group

Test:

```bash
docker info
docker compose version
```

### 1) Run setup

From the repo folder:

```bash
./scripts/setup.sh
```

The script asks 3 things:

- **Config/state directory** (default is fine)
- **Workspace directory (RW)**: this is the **only** folder OpenClaw can read/write.
- **OpenClaw source clone directory** (default is fine)

### 2) Open the dashboard

```bash
./scripts/dashboard.sh
```

If you open `http://127.0.0.1:18789/` without a token you may see “unauthorized” — that’s normal.
Use the tokenized URL printed by `dashboard.sh`.

### 3) Start/stop (later)

- Start:

```bash
./scripts/up.sh
```

- Logs:

```bash
./scripts/logs.sh
```

- Stop:

```bash
./scripts/down.sh
```

### Upgrading

To pull the latest version and restart:

```bash
./scripts/upgrade.sh
```

This fetches the latest source, rebuilds the Docker image, and restarts the gateway. Your config and data are untouched.

### Common issues

#### “permission denied” / “Cannot connect to the Docker daemon”

Option A (quick fix):

```bash
sudo ./scripts/setup.sh
```

Option B (recommended): add user to docker group (then log out/in once):

```bash
sudo usermod -aG docker "$USER"
```

#### Port already in use (18789/18790)

You can change ports in `.env`:

- `OPENCLAW_GATEWAY_PORT`
- `OPENCLAW_BRIDGE_PORT`
