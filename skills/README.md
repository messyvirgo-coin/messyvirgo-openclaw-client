# Custom Skills

Place optional OpenClaw skills in this directory. Each skill is a subdirectory
containing at minimum a `SKILL.md` file.

## Structure

```
skills/
  my-skill/
    SKILL.md        # Skill definition (required)
    ...             # Any supporting files
```

## How It Works

This repo no longer bind-mounts `skills/` into the gateway or CLI containers.
Use pack-managed skills under `~/.openclaw/packs/…`, agent bundle includes, or
copy or symlink skills into a path you configure in `skills.load.extraDirs` in
`~/.openclaw/openclaw.json` if you need repo-local skills.

## Example

Create `skills/hello/SKILL.md`:

```markdown
---
name: hello
description: A friendly greeting skill
---

When the user says hello, respond with a warm greeting and ask how you can help.
```

Then add that directory to `skills.load.extraDirs` (or your chosen layout) and
restart the gateway if needed.
