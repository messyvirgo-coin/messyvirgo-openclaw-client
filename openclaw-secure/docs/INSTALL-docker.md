# Docker install (Linux + macOS)

This is the **canonical** install guide for **OpenClaw-secure** (this Messy Virgo **wrapper** repo). It covers:

- installing the hardened Docker stack
- dashboard + device pairing (**Linux** vs **macOS** differ)
- smoke checks and optional semantic memory verification
- the default Messy Virgo agent + Telegram

The upstream OpenClaw **source** used to build the image is cloned by `setup.sh` into `OPENCLAW_SRC_DIR` (default under your config dir)—you do **not** clone that manually for a normal install.

---

## 0) Requirements

### Linux

- Docker Engine + Docker Compose v2 (`docker compose` must work)
- Optional but recommended: your user is in the `docker` group

### macOS

- **Docker Desktop** installed and running (“Docker is running”)

### Both

- This **wrapper** repository cloned locally (see §1)

Test Docker:

```bash
docker info
docker compose version
```

---

## 1) Clone this wrapper repository

Clone **this** repo (the client/wrapper that contains `openclaw-secure/`), **not** only `openclaw/openclaw`. Upstream OpenClaw is fetched during `setup.sh` when the image is built.

```bash
git clone <URL-of-this-wrapper-repo>
cd <repo-directory>   # e.g. messyvirgo-openclaw-client
```

---

## 2) Prepare `.env`

```bash
cp .env.secure.example .env
```

Use **[`.env.secure.example`](../../.env.secure.example)** for Docker. Native installs use **[`.env.raw.example`](../../.env.raw.example)** — same filename **`.env`** at the repo root; only the template you copy from differs.

**Optional — VPS / cloud:** add [`docker-compose.cloud.yml`](../docker-compose.cloud.yml) (log rotation, `restart: always`) by listing it in your `docker compose -f …` chain; wrapper `up.sh` / `setup.sh` do not load it automatically.

Set at least:

- `OPENROUTER_API_KEY` — chat models **and** semantic memory embeddings ([MEMORY.md](../../docs/MEMORY.md))
- `BRAVE_API_KEY` — if you use Brave-backed tools
- `TAVILY_API_KEY` — if you use the Tavily plugin (`config/openclaw.json` → `plugins.entries.tavily`)

Messy Virgo MCP tools (optional):

- `MESSY_VIRGO_MCP_URL`, `MESSY_VIRGO_API_KEY`

Paths and clones (optional overrides):

- `OPENCLAW_GIT_REPO` — default upstream [`openclaw/openclaw`](https://github.com/openclaw/openclaw)
- `OPENCLAW_SRC_DIR`, `OPENCLAW_IMAGE`, `OPENCLAW_CONFIG_DIR`, `OPENCLAW_WORKSPACES_DIR`

---

## 3) Run one-time setup

```bash
./openclaw-secure/scripts/setup.sh
```

Use `./openclaw-secure/scripts/setup.sh --interactive` for prompts.

`setup.sh` builds the image, deploys config/workspaces (first time), patches gateway defaults, and starts the gateway—so you can continue without running `up.sh` first.

---

## 4) macOS only: Docker Desktop file sharing

If your workspace, config, or OpenClaw source paths live outside Docker Desktop’s allowed paths, add them under **Settings → Resources → File Sharing**, apply, and restart Docker Desktop if prompted.

Linux users can skip this section.

---

## 5) Open the dashboard

```bash
./openclaw-secure/scripts/dashboard.sh
```

Open the full URL including `#token=...`. Without the token you may see `unauthorized`.

**Port binding notes:**

- The default stack merges **`docker-compose.ports.localhost.yml`**, which publishes the gateway on **`127.0.0.1`** (see `openclaw-secure/docker-compose*.yml`).
- On **Linux**, if `docker-compose.linux-hostnet.yml` is used (`network_mode: host`), `docker ps` may show **no** published ports; use the tokenized URL on `http://127.0.0.1:<port>/` per your `.env`. Wrapper scripts set **`OPENCLAW_GATEWAY_BIND=loopback`** for that stack so the gateway stays localhost-only (your `.env` value is not used there).
- On **macOS**, Docker Desktop sometimes makes port behavior feel broader than strict loopback; the gateway remains **token-authenticated**.

---

## 6) Approve the first device pairing

### Linux device pairing

```bash
./openclaw-secure/scripts/cli.sh devices list
./openclaw-secure/scripts/cli.sh devices approve <requestId>
```

Copy `<requestId>` from the pending entry in `devices list`.

### macOS device pairing

On Docker Desktop, `cli.sh devices …` may hit websocket errors (`1006`, timeouts). Run the same commands **inside** the gateway container:

```bash
bash -lc 'source ./openclaw-secure/scripts/_common.sh; compose exec -T openclaw-gateway node /app/openclaw.mjs devices list'
bash -lc 'source ./openclaw-secure/scripts/_common.sh; compose exec -T openclaw-gateway node /app/openclaw.mjs devices approve <requestId>'
```

Refresh the dashboard after approving.

---

## 7) Two ways to run CLI commands

**Option A — one-shot from host:**

```bash
./openclaw-secure/scripts/cli.sh status
./openclaw-secure/scripts/cli.sh channels list
```

**Option B — interactive shell:**

```bash
./openclaw-secure/scripts/cli-shell.sh
openclaw status
```

---

## 8) Quick smoke checks

```bash
./openclaw-secure/scripts/cli.sh health --json
./openclaw-secure/scripts/cli.sh status
./openclaw-secure/scripts/security-audit.sh
```

Optional agent identity checks:

```bash
./openclaw-secure/scripts/cli.sh agent --agent main --message "State your name in one sentence."
```

If an agent acts like first-run onboarding, remove `BOOTSTRAP.md` from that workspace (or use setup/upgrade `--cleanup-bootstrap`), then restart.

### Semantic memory (no extra setup)

Memory is already enabled in the deployed `config/openclaw.json`. Optional check:

```bash
./openclaw-secure/scripts/cli.sh memory status --deep
```

See [MEMORY.md](../../docs/MEMORY.md) and [VERIFY.md](VERIFY.md) §6.

---

## 9) Optional: Messy Virgo MCP tools + Telegram

Skip if you only want the default Messy Virgo setup.

### 9.1 Messy Virgo credentials

```bash
MESSY_VIRGO_MCP_URL=https://api.messyvirgo.com/mcp
MESSY_VIRGO_API_KEY=<your_key>
```

**Linux — local MCP on the same machine:**

- Default bridge networking: often `http://172.17.0.1:8000/mcp`
- `./openclaw-secure/scripts/up-linux-hostnet.sh` (host network): `http://localhost:8000/mcp`

### 9.2 Telegram

See [docs/TELEGRAM.md](../../docs/TELEGRAM.md). Register channels:

```bash
./openclaw-secure/scripts/cli.sh channels add --channel telegram --account <account> --name "<agent-name>" --token "<token>"
./openclaw-secure/scripts/cli.sh agents bind --agent <agent-name> --bind telegram:<account>
```

Group policy example (`allowlist`):

```bash
./openclaw-secure/scripts/cli.sh config set channels.telegram.groupPolicy '"allowlist"'
./openclaw-secure/scripts/cli.sh config set channels.telegram.accounts.<account>.groupPolicy '"allowlist"'
./openclaw-secure/scripts/cli.sh config set channels.telegram.accounts.<account>.groupAllowFrom '["tg:<telegram_user_id>"]'
```

Restart after channel changes. Approve bot pairing:

```bash
./openclaw-secure/scripts/cli.sh pairing approve telegram <pairing_code>
```

---

## 10) Start / stop / logs

```bash
./openclaw-secure/scripts/up.sh
./openclaw-secure/scripts/logs.sh
./openclaw-secure/scripts/down.sh
```

---

## 11) Upgrade

[openclaw/openclaw](https://github.com/openclaw/openclaw) publishes **`v*`** tags. **`setup.sh`** / **`upgrade.sh`** fetch **`OPENCLAW_GIT_REPO`** and check out the latest tag unless **`OPENCLAW_GIT_REF`** is set (e.g. **`main`**).

```bash
./openclaw-secure/scripts/upgrade.sh
```

Upstream also documents global `npm` installs and `openclaw update`; this Docker layout rebuilds the image via **`upgrade.sh`** instead. Config and workspaces are kept unless you pass flags such as **`--sync-config`**.

---

## 12) Uninstall

See [UNINSTALL.md](UNINSTALL.md).

---

## Common issues

### Linux: Docker permission denied

```bash
sudo usermod -aG docker "$USER"
# log out and back in
```

Or one-off: `sudo ./openclaw-secure/scripts/setup.sh`.

### macOS: Docker not running / API mismatch

- Open Docker Desktop and wait until it is running.
- Try `docker context use desktop-linux` then `docker info`.
- This repo sets `DOCKER_API_VERSION=1.44` on macOS when unset (see `_common.sh`).

### macOS: file permission / volume errors

- Confirm paths exist and Docker **File Sharing** includes them (§4).

### Pairing loop

- Use the **full** tokenized dashboard URL.
- Approve device (Linux: §6 Linux; macOS: §6 macOS).
- Restart: `down.sh` → `up.sh` → `dashboard.sh`.

### Gateway token mismatch

Restart gateway, open fresh tokenized URL; paste token from `.env` in Control UI if needed.

### Ports in use

Change `OPENCLAW_GATEWAY_PORT` / `OPENCLAW_BRIDGE_PORT` in `.env`, then `down.sh` → `up.sh` → `dashboard.sh`.
