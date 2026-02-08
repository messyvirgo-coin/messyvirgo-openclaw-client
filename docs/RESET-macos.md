# macOS clean re-setup (OpenClaw Docker wrapper)

Use this when OpenClaw “kind of works” but the gateway/networking got weird and you want a simple reset.

## 0) Prerequisites

- Docker Desktop installed
- This repo folder downloaded/cloned on the Mac

## 1) Restart Docker Desktop (fixes most networking issues)

1. Quit Docker Desktop (Docker menu → Quit Docker Desktop).
2. Start Docker Desktop again.
3. Wait until it says **“Docker is running”**.

## 2) Open Terminal in the repo folder

Open Terminal and `cd` into the folder that contains `docker-compose.yml` and the `scripts/` directory.

## 3) Stop OpenClaw containers

```bash
./scripts/down.sh
```

## 4) Optional: full reset (fresh start)

This stops containers, removes project volumes, and (optionally) deletes config/src/workspace.

Safe default (project-only: containers + volumes):

```bash
./scripts/reset.sh
```

Fresh start (also delete OpenClaw config/state + source clone):

```bash
./scripts/reset.sh --delete-config --delete-src
```

If you also want to delete the workspace folder (dangerous if it points to a real project directory):

```bash
./scripts/reset.sh --delete-config --delete-src --delete-workspace
```

## 5) Reset the wrapper `.env` (recommended)

This repo’s `.env` contains tokens/settings. If things are messy, remove it so setup can regenerate it:

```bash
rm -f .env
```

## 6) Run the guided setup (rebuilds image + runs onboarding)

```bash
./scripts/setup.sh
```

When asked for the workspace folder:

- Beginner option: accept the default `~/OpenClawWorkspace`

## 7) Docker Desktop “File Sharing” (common macOS issue)

If you chose a workspace folder outside `~/...`, Docker Desktop must be allowed to access it:

- Docker Desktop → Settings → Resources → File Sharing
- Add the chosen workspace folder
- Apply & Restart

## 8) Start OpenClaw and open the dashboard

Start:

```bash
./scripts/up.sh
```

Get the tokenized dashboard URL:

```bash
./scripts/dashboard.sh
```

Open the printed URL in your browser.

## 9) Telegram bot: make it reply (DM)

1. Find the configured bot username:

```bash
./scripts/cli.sh health --json
```

Look for: `channels.telegram.probe.bot.username`

1. In Telegram, DM that exact bot:

- Send `/start`
- Then send `hi`

1. Approve pairing (first time only):

```bash
./scripts/cli.sh pairing list telegram
./scripts/cli.sh pairing approve telegram <CODE>
```

Then message the bot again — it should reply.

## If it still doesn’t work (copy/paste outputs to the person helping you)

```bash
./scripts/cli.sh health --json
./scripts/cli.sh status --deep
./scripts/logs.sh
```
