# X (Twitter) account monitoring — skill search results

You want to monitor these 4 official Messy Virgo X accounts:

- **@MEssyVirgoCoin**
- **@MessyVirgoBot**
- **@MessyVirgoF**
- **@MessyVirgoM**

Below are the skills found and how to use one for monitoring.

---

## Skills found

### 1. **x-api** (recommended for monitoring)

| | |
|---|--|
| **Source** | [shalomma/social-media-research](https://github.com/shalomma/social-media-research) → `.claude/skills/x-api` |
| **Registry** | [claude-plugins.dev](https://claude-plugins.dev/skills/@shalomma/social-media-research/x-api) (Agent Skills format; not ClawHub) |
| **Auth** | **twitterapi.io** API key (`XAPI_IO_API_KEY`) |
| **Fits monitoring?** | **Yes.** Search supports `from:username` and returns timeline JSON. You can query each of the 4 handles (e.g. `from:MEssyVirgoCoin`, `from:MessyVirgoBot`, …) and get recent tweets. |

**Capabilities:**

- **User info:** `python3 twitter.py userinfo <screenname>`
- **Search tweets (including by user):** `python3 twitter.py search "from:MEssyVirgoCoin" --type Latest`

So the agent can “monitor” the 4 accounts by running search with `from:<handle>` for each. This repo provides an **X Monitor dashboard** at `http://127.0.0.1:18788/` that shows recent tweets for all 4 accounts in one place (see [DASHBOARD.md](DASHBOARD.md)); the agent can also use the skill to summarize.

**Requirements:** Python 3, `XAPI_IO_API_KEY` from [twitterapi.io](https://twitterapi.io). The skill uses a Typer CLI and returns JSON.

---

### 2. **Bird** (OpenClaw / clawdbot)

| | |
|---|--|
| **Source** | Listed on [agent-skills.md (clawdbot)](https://agent-skills.md/authors/clawdbot) as “X/Twitter CLI for reading, searching, posting, and engagement via cookies.” |
| **Auth** | Cookie-based (browser/session), not API key. |
| **Fits monitoring?** | **Partially.** Read + search is enough for monitoring, but cookie setup is more involved and may not suit a Docker/headless gateway. |

Bird is from the OpenClaw/clawdbot ecosystem but is **not** in the current [openclaw/openclaw](https://github.com/openclaw/openclaw) `skills/` list on GitHub; it may live in another repo or branch. No install path was verified in this search.

---

### 3. ClawHub

- **clawhub search** was not run successfully (CLI/Node issue in this environment).
- ClawHub does **not** expose a “VirusTotal-approved only” or “verified” filter; any skill you can install has passed the registry’s VirusTotal gate (non-malicious).
- There was **no** dedicated “X account monitor” skill found on the ClawHub site or in search results.

---

## Recommendation

Use **x-api** for monitoring the 4 X accounts:

1. **Install the skill** into your OpenClaw workspace (see below).
2. **Get an API key** from [twitterapi.io](https://twitterapi.io) and set `XAPI_IO_API_KEY` (e.g. in `openclaw.json` under `skills.entries["x-api"].env` or in the container env).
3. **Ask the agent** to run the skill, e.g.:
   - “Search latest tweets from @MEssyVirgoCoin using the x-api skill.”
   - “For each of @MEssyVirgoCoin, @MessyVirgoBot, @MessyVirgoF, @MessyVirgoM, get the latest 5 tweets and summarize.”
4. Optionally, **build a small dashboard** that calls the same search (or the agent) and displays results; OpenClaw’s Control UI does not show X activity by itself.

---

## Installing the x-api skill

The x-api skill lives in a GitHub repo (not ClawHub). To add it to your workspace:

1. Clone or download [shalomma/social-media-research](https://github.com/shalomma/social-media-research).
2. Copy the skill folder into your OpenClaw workspace skills directory:
   - From the repo: `.claude/skills/x-api/` (contents: `SKILL.md`, `src/`, `requirements.txt`).
   - To: `$OPENCLAW_WORKSPACE_DIR/skills/x-api/` (so the skill is named `x-api`).
3. Ensure the gateway (or CLI) can run Python 3 and has access to `XAPI_IO_API_KEY`.
4. Restart the gateway or start a new session so OpenClaw loads the new skill.

If you use a script similar to `install-openclaw-skills.sh`, you can add a step to clone `shalomma/social-media-research` and copy `.claude/skills/x-api` into `$OPENCLAW_WORKSPACE_DIR/skills/x-api`.

---

## Security note

x-api is **third-party** (shalomma, not OpenClaw). It was not verified via ClawHub’s VirusTotal pipeline. Treat it as untrusted: review `SKILL.md` and the code under `src/` before use, and avoid giving it more privileges or secrets than needed (only `XAPI_IO_API_KEY` for twitterapi.io).
