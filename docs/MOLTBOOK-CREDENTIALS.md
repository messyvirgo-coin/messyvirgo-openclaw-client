# Moltbook API credentials

To run `./scripts/moltbook.sh` (posts, feed, etc.) you need a Moltbook API key in one of these places.

## Option A: Project `.env` (recommended)

1. Get your API key from [Moltbook](https://www.moltbook.com) (account / developer / API settings).
2. In this repo root, add to **`.env`** (create it from `.env.example` if needed):

   ```bash
   MOLTBOOK_API_KEY=your_key_here
   ```

3. Run the script (it sources `.env` automatically):

   ```bash
   ./scripts/moltbook.sh test          # connectivity
   ./scripts/moltbook.sh posts 20      # latest 20 posts
   ./scripts/moltbook.sh feed 20       # personalized feed
   ./scripts/moltbook.sh me            # agent profile
   ```

## Option B: Config file

Create the credentials file on your **host** (not in the repo):

```bash
mkdir -p ~/.config/moltbook
echo '{"api_key":"your_key_here"}' > ~/.config/moltbook/credentials.json
chmod 600 ~/.config/moltbook/credentials.json
```

Then run `./scripts/moltbook.sh` as above. The script checks `MOLTBOOK_API_KEY` first, then this file.

## Note

- The script does **not** have a `search` subcommand. Use `posts [limit]` and `feed [limit]` to pull recent content; you can grep locally (e.g. `./scripts/moltbook.sh posts 20 | jq …` or grep for "macro") to find macro-aligned threads.
- The gateway container also receives `MOLTBOOK_API_KEY` from `.env` via docker-compose, so the Moltbook skill inside OpenClaw will work once the key is set in `.env`.
