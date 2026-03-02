# Strategy: Running Your Own OpenClaw Fork

## Two-Repo Architecture

```text
messyvirgo-openclaw          (fork — clean mirror of openclaw/openclaw)
messyvirgo-openclaw-client   (client — Docker wrapper, configs, skills, docs)
```

**The fork stays clean.** It is a 1:1 mirror of upstream with zero divergence.
All customization lives in the client repo. This means:

- Upstream merges are always fast-forward — zero merge conflicts, ever.
- The Dockerfile and build tooling come from the fork (upstream).
- Config, skills, compose overlays, and scripts live in the client repo.

## How Upstream Sync Works

```bash
# In your fork repo:
git remote add upstream https://github.com/openclaw/openclaw.git  # once
git fetch upstream
git merge --ff-only upstream/main
git push origin main
```

Then in the client repo, run `./scripts/upgrade.sh` to pull the latest fork
code, rebuild the Docker image, and restart the gateway.

## Config Strategy

This client repo currently uses a single config template:

| File | Purpose |
| --- | --- |
| `config/openclaw.json` | Unified gateway, model, agent, and skills configuration |

During `setup.sh`, `config/openclaw.json` is copied to `$OPENCLAW_CONFIG_DIR`
(default `~/.openclaw-secure`) if it does not already exist. Existing config
is left untouched unless you replace it manually.

### Environment Variable Substitution

Config values like `${ANTHROPIC_API_KEY}` are resolved at runtime from the
container's environment. Set API keys in your `.env` file or export them
before running compose.

## Custom Skills

Place skill directories under `skills/` in the client repo:

```text
skills/
  my-skill/
    SKILL.md
```

The `docker-compose.skills.yml` overlay mounts this directory read-only at
`/home/node/custom-skills` inside the container. The master config tells
OpenClaw to load from that path with file watching enabled.

See `skills/README.md` for details and examples.

## Multi-Agent Architecture

The client ships a 4-agent setup where a main orchestrator (Messy Virgo)
delegates specialized tasks to sub-agents:

```text
Main (Messy Virgo) — Gemini 2.5 Flash
├── Coder       — Qwen3 Coder
├── Researcher  — Gemini 2.5 Flash
└── Planner     — Kimi K2.5 (thinking: high)
```

- **Main** handles direct chat and simple questions. Delegates complex tasks.
- **Coder** handles code writing, debugging, scripts (Qwen3 Coder).
- **Researcher** handles web search, current data, document analysis (Gemini 2.5 Flash).
- **Planner** handles multi-step planning, architecture, strategy (Kimi K2.5, deep thinking).

### How it works

The main agent uses `sessions_spawn` to delegate tasks, passing the
target agent ID and thinking level. Sub-agents report results back
automatically. Only the main agent can spawn sub-agents (`maxSpawnDepth=1`).

### Workspace templates

Each agent's behavior is defined by Markdown bootstrap files in
`config/workspaces/<agentId>/`:

| File | Purpose |
| --- | --- |
| `AGENTS.md` | Role definition, guidelines, delegation rules |
| `SOUL.md` | Personality and communication style (main agent only) |

These are deployed to:

- `main` -> `$OPENCLAW_WORKSPACES_DIR/main`
- `coder` -> `$OPENCLAW_WORKSPACES_DIR/coder`
- `researcher` -> `$OPENCLAW_WORKSPACES_DIR/researcher`
- `planner` -> `$OPENCLAW_WORKSPACES_DIR/planner`

By default, changed files are preserved. You can opt into safe sync on setup/upgrade:

```bash
./scripts/setup.sh --sync-workspaces
./scripts/upgrade.sh --sync-workspaces
```

Both commands create timestamped `.bak` backups before overwriting changed template files.

### Customizing agents

Edit `config/openclaw.json` to change model assignments, add agents,
or adjust sub-agent policies. Edit the workspace templates under
`config/workspaces/` to change agent behavior and instructions.

After editing, restart the gateway to pick up changes.

## Deployment

### Local (default)

```bash
cp envs/local.env.example .env   # or run setup.sh which generates .env
./scripts/setup.sh
./scripts/up.sh
```

Ports are bound to `127.0.0.1` only (via `docker-compose.ports.localhost.yml`).

### Cloud

```bash
cp envs/cloud.env.example .env
# Edit .env: set API keys, adjust bind/ports as needed
./scripts/setup.sh
```

For production, add the cloud overlay to your compose commands. Edit
`_common.sh` or run manually:

```bash
docker compose \
  -f docker-compose.yml \
  -f docker-compose.secure.yml \
  -f docker-compose.ports.localhost.yml \
  -f docker-compose.skills.yml \
  -f docker-compose.cloud.yml \
  up -d
```

The cloud overlay adds `restart: always` and log rotation.

### Linux Host Network Mode

For Linux hosts where Docker port publishing is problematic, use:

```bash
./scripts/up-linux-hostnet.sh
```

This uses `network_mode: host` and the gateway binds to loopback directly.

## Upgrading

```bash
# 1. Sync your fork from upstream (in the fork repo)
cd ../messyvirgo-openclaw
git fetch upstream
git merge --ff-only upstream/main
git push origin main

# 2. Rebuild and restart (in the client repo)
cd ../messyvirgo-openclaw-client
./scripts/upgrade.sh
```

The upgrade script:

1. Pulls latest from your fork (`git pull --ff-only`)
2. Rebuilds the Docker image
3. Restarts the gateway container

By default, your config and workspace files remain untouched. To refresh
workspace templates with backups, use:

```bash
./scripts/upgrade.sh --sync-workspaces
```

## File Layout

```text
messyvirgo-openclaw-client/
  .env.example                        # Template with all env vars
  config/
    openclaw.json                     # Unified runtime config
    workspaces/
      main/AGENTS.md, SOUL.md          # Main agent behavior + persona
      coder/AGENTS.md                   # Coder sub-agent behavior
      researcher/AGENTS.md              # Researcher sub-agent behavior
      planner/AGENTS.md                 # Planner sub-agent behavior
  docker-compose.yml                  # Base services
  docker-compose.secure.yml           # Hardening overlay
  docker-compose.ports.localhost.yml  # Localhost port binding
  docker-compose.linux-hostnet.yml    # Linux host network mode
  docker-compose.skills.yml           # Custom skills volume mount
  docker-compose.cloud.yml            # Cloud deployment (restart + logging)
  envs/
    local.env.example                 # Local dev defaults
    cloud.env.example                 # Cloud deployment defaults
  scripts/
    setup.sh                          # Bootstrap (clone, build, onboard)
    upgrade.sh                        # Pull + rebuild + restart
    up.sh / down.sh                   # Start/stop gateway
    cli.sh                            # Run CLI commands
    ...
  skills/                             # Your custom skills (gitignored)
    README.md
  docs/
    STRATEGY.md                       # This file
    ...
```
