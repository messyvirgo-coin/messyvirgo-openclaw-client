# Agent avatar assets

Use per-agent directories:

- `assets/avatars/main/`
- `assets/avatars/coder/`
- `assets/avatars/researcher/`
- `assets/avatars/planner/`

For the main agent, place the image at:

- `assets/avatars/main/messy-virgo.png`
- and reference it in `IDENTITY.md` as `avatars/messy-virgo.png`

Recommended specs:

- Square image (1:1)
- PNG or WEBP
- 1024×1024 preferred (512×512 also fine)
- Transparent background optional

Deployment behavior:

- `setup.sh` and `upgrade.sh` sync `assets/avatars/<agent-id>/` into `<workspace>/<agent-id>/avatars/`.
- Existing files are preserved unless `--sync-workspaces` is used (with timestamped backups).
