# Uninstall (Linux + macOS)

This guide applies to both Linux and macOS. You do **not** need separate uninstall files.

The wrapper reset script is cross-platform and already handles platform-specific compose behavior.

## 1) Go to the wrapper repo

```bash
cd /path/to/messyvirgo-openclaw-client
```

## 2) Stop running containers

```bash
./scripts/down.sh
```

## 3) Choose uninstall level

### A) Full uninstall for this wrapper (recommended when removing everything)

Removes:

- wrapper containers + volumes
- OpenClaw config/state directory
- source clone used for image builds
- configured workspace directory
- local wrapper image tag

```bash
./scripts/reset.sh --delete-config --delete-src --delete-workspace --remove-image --yes
```

### B) Keep your workspace data, remove runtime only

Removes containers/config/source/image, but keeps the workspace folder:

```bash
./scripts/reset.sh --delete-config --delete-src --remove-image --yes
```

### C) Stop/remove containers + wrapper volumes only (least destructive)

```bash
./scripts/reset.sh
```

## 4) Optional: remove all unused Docker resources system-wide

Only run this if you explicitly want cleanup beyond this project:

```bash
./scripts/reset.sh --system-prune --yes
```

This affects your whole Docker host, not just OpenClaw.

## Notes

- `--delete-workspace` deletes `OPENCLAW_WORKSPACE_DIR` from your `.env`.
- If your workspace path points to a real project directory, that directory will be deleted.
- `--yes` skips confirmations. Remove `--yes` if you want interactive prompts.
