# Docker install (Linux + macOS)

Wrapper repo for **OpenClaw**; upstream source is cloned during `setup.sh` into `OPENCLAW_SRC_DIR` (default under your config dir).

## Requirements

- **Linux:** Docker Engine + Compose v2 (`docker compose`).
- **macOS:** Docker Desktop running.
- This repo cloned locally.

```bash
docker info && docker compose version
```

## 1. Clone

```bash
git clone <your-fork-or-upstream-url>
cd <repo>
```

## 2. `.env`

```bash
cp .env.secure.example .env
```

**Required / common:** `OPENROUTER_API_KEY` (chat + memory embeddings). Optional: `BRAVE_API_KEY`, `TAVILY_API_KEY`, `MV_API_URL` / `MV_API_KEY` (Messy Virgo CLI in container), `MESSYVIRGO_CLI_VERSION`, `OPENCLAW_GIT_REPO`, `OPENCLAW_SRC_DIR`, `OPENCLAW_CONFIG_DIR`, `OPENCLAW_WORKSPACES_DIR`.

VPS: optionally add [`docker-compose.cloud.yml`](../docker-compose.cloud.yml) to your compose `-f` list (not loaded by default).

## 3. Setup

```bash
./openclaw-secure/scripts/setup.sh
```

`--interactive` for prompts. Builds image, seeds config/workspaces, patches gateway defaults, starts gateway.

## 4. macOS: file sharing

If config/workspace/source paths sit outside Docker Desktop **Settings → Resources → File Sharing**, add them and restart Docker.

## 5. Dashboard

```bash
./openclaw-secure/scripts/dashboard.sh
```

Use the full URL including `#token=…`. Default compose publishes **127.0.0.1**; Linux **host-network** compose may show no ports in `docker ps` — still open `http://127.0.0.1:<OPENCLAW_GATEWAY_PORT>/`.

## 6. Device pairing

**Linux:**

```bash
./openclaw-secure/scripts/cli.sh devices list
./openclaw-secure/scripts/cli.sh devices approve <requestId>
```

**macOS (if host `cli.sh devices` fails):** run inside the gateway container:

```bash
bash -lc 'source ./openclaw-secure/scripts/_common.sh; compose exec -T openclaw-gateway node /app/openclaw.mjs devices list'
bash -lc 'source ./openclaw-secure/scripts/_common.sh; compose exec -T openclaw-gateway node /app/openclaw.mjs devices approve <requestId>'
```

## 7. CLI

```bash
./openclaw-secure/scripts/cli.sh status
# or: ./openclaw-secure/scripts/cli-shell.sh  then  openclaw …
```

## 8. Checks

```bash
./openclaw-secure/scripts/cli.sh health --json
./openclaw-secure/scripts/security-audit.sh
./openclaw-secure/scripts/cli.sh memory status --deep   # optional
```

[VERIFY.md](VERIFY.md), [../../docs/MEMORY.md](../../docs/MEMORY.md). If the agent is stuck in onboarding, remove workspace `BOOTSTRAP.md` or use `upgrade.sh --cleanup-bootstrap`.

## 9. Telegram / Messy Virgo CLI

[../../docs/TELEGRAM.md](../../docs/TELEGRAM.md). Image includes `@messyvirgo/cli` (`mv`); quick check:

```bash
bash -lc 'source ./openclaw-secure/scripts/_common.sh && compose run --rm --entrypoint mv openclaw-cli --help'
```

## 10. Lifecycle

```bash
./openclaw-secure/scripts/up.sh
./openclaw-secure/scripts/logs.sh
./openclaw-secure/scripts/down.sh
```

## 11. Upgrade

```bash
./openclaw-secure/scripts/upgrade.sh
```

Tracks the highest stable upstream `v*` tag by semver (prereleases with `-beta` in the tag name are skipped unless no other `v*` tags exist) unless `OPENCLAW_GIT_REF` is set (e.g. `main`). Rebuilds image (including `npm` + `@messyvirgo/cli` overlay). `--sync-config` / `--sync-workspaces` overwrite deployed templates (back up first).

## 12. Uninstall

[UNINSTALL.md](UNINSTALL.md).

## Common issues

- **Docker permission denied (Linux):** `sudo usermod -aG docker "$USER"` (re-login) or `sudo ./openclaw-secure/scripts/setup.sh`.
- **macOS Docker:** ensure Desktop is running; try `docker context use desktop-linux`. Repo may set `DOCKER_API_VERSION=1.44` when unset.
- **Pairing:** tokenized dashboard URL; approve device (see **Device pairing** above); `down.sh` → `up.sh`.
- **Ports:** change `OPENCLAW_GATEWAY_PORT` / `OPENCLAW_BRIDGE_PORT`, then restart stack.
