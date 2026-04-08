# Uninstall (Docker)

From the wrapper repo:

```bash
./openclaw-secure/scripts/down.sh
```

**Levels** (see `reset.sh --help`):

| Goal | Command |
|------|---------|
| Containers + volumes only | `./openclaw-secure/scripts/reset.sh` |
| + delete config, source clone, image (keep workspace) | `./openclaw-secure/scripts/reset.sh --delete-config --delete-src --remove-image --yes` |
| + delete workspace dir from `.env` | add `--delete-workspace` (dangerous if path is a real project) |
| Docker system prune (host-wide) | `./openclaw-secure/scripts/reset.sh --system-prune --yes` |

Drop `--yes` for prompts.
