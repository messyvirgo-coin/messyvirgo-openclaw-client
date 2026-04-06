# OpenClaw in this wrapper

This repository is a **deployment wrapper** around upstream [OpenClaw](https://github.com/openclaw/openclaw). Day-to-day behavior, CLI, and gateway semantics are defined upstream; this repo supplies shared **templates**, **compose/scripts**, and **Messy Virgo–specific defaults**.

## Where things live

| Topic | In this repo | Upstream |
|--------|----------------|----------|
| Install (Docker) | [openclaw-secure/docs/INSTALL-docker.md](../openclaw-secure/docs/INSTALL-docker.md) | [docs.openclaw.ai](https://docs.openclaw.ai) |
| Install (native) | [openclaw-raw/docs/INSTALL-native.md](../openclaw-raw/docs/INSTALL-native.md) | same |
| Verify / health | [openclaw-secure/docs/VERIFY.md](../openclaw-secure/docs/VERIFY.md) | — |
| Baseline gateway config (templates) | `config/openclaw.json` (Docker), `config/openclaw.native.json` (native) | [Configuration reference](https://docs.openclaw.ai/gateway/configuration-reference) |
| Env templates | `.env.secure.example`, `.env.raw.example` | — |
| Messy Virgo agents & pack skills | `../messyvirgo-openclaw-agents` (separate repo) | — |

## Wrapper docs (topic guides)

- **[TELEGRAM.md](TELEGRAM.md)** — Bot registration, pairing, group policy, **Telegram streaming** and troubleshooting.
- **[MEMORY.md](MEMORY.md)** — Semantic memory, embeddings, `memory-core`, dreaming, template keys.
- **[PLUGINS.md](PLUGINS.md)** — Installing and inspecting plugins via the wrapper CLI.
- **[SECURITY.md](SECURITY.md)** — Threat model, ports, sandboxing defaults in Docker.

## Configuration workflow

1. **Templates** in `config/` are copied or merged when you run `setup.sh` / `upgrade.sh` (see each script’s flags; back up `$OPENCLAW_CONFIG_DIR` before forcing overwrites).
2. **Runtime truth** is `$OPENCLAW_CONFIG_DIR/openclaw.json` on the host (mounted into the gateway container for Docker).
3. **Agent list and models** in the template are starting points; pack installs (e.g. `mv-t1`) can add agents and bindings—see [README.md](../README.md) § Agent packs.

## Useful upstream entry points

- [Gateway](https://docs.openclaw.ai/gateway) · [CLI](https://docs.openclaw.ai/cli) · [Channels](https://docs.openclaw.ai/channels)
- [Telegram channel](https://docs.openclaw.ai/channels/telegram) (full feature list vs this repo’s short setup guide)
- [Agent loop / tools](https://docs.openclaw.ai/concepts/agent-loop)
