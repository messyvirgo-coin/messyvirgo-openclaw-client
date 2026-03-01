# Custom Skills

Place custom OpenClaw skills in this directory. Each skill is a subdirectory
containing at minimum a `SKILL.md` file.

## Structure

```
skills/
  my-skill/
    SKILL.md        # Skill definition (required)
    ...             # Any supporting files
```

## How It Works

The `docker-compose.skills.yml` overlay mounts this directory as
`/home/node/custom-skills` (read-only) inside both the gateway and CLI
containers. The master config (`config/openclaw.json`) tells OpenClaw to
load skills from that path with file watching enabled.

## Example

Create `skills/hello/SKILL.md`:

```markdown
---
name: hello
description: A friendly greeting skill
---

When the user says hello, respond with a warm greeting and ask how you can help.
```

Then restart the gateway (`./scripts/down.sh && ./scripts/up.sh`) or wait
for the file watcher to pick it up.
