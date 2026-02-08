## macOS install (beginner-friendly)

### 0) Requirements

- Install **Docker Desktop** (default installer).
- Open Docker Desktop and wait until it says: **“Docker is running”**.

### 1) Get this repo

If you received this repo as a ZIP: unzip it and open Terminal in that folder.

### 2) Run one-time setup

In Terminal, from the repo folder:

```bash
./scripts/setup.sh
```

The script asks 3 things:

- **Config/state directory** (default is fine)
- **Workspace directory (RW)**: this is the **only** folder OpenClaw can read/write.
  - Beginner: keep the default `~/OpenClawWorkspace`
  - Advanced: point it at your project directory (e.g. `~/Projects/my-project`)
- **OpenClaw source clone directory** (default is fine; used only to build the Docker image)

### 3) Important: Docker Desktop “File Sharing”

If you chose a workspace outside `~/...`, Docker Desktop must be allowed to access it:

- Docker Desktop → Settings → Resources → File Sharing
- Add the workspace directory (if needed)
- Apply & Restart

### 4) Open the dashboard

```bash
./scripts/dashboard.sh
```

This prints a tokenized URL that you can open in Safari/Chrome.

### 5) Start/stop (later)

- Start:

```bash
./scripts/up.sh
```

- Logs:

```bash
./scripts/logs.sh
```

- Stop:

```bash
./scripts/down.sh
```

### Common issues

#### “Docker is installed but not running”

- Open Docker Desktop
- Wait 10–30 seconds
- Run `./scripts/setup.sh` again

**If `docker info` shows "Server: ERROR: Error response from daemon"** and you use the Docker CLI from Homebrew while Docker Desktop has a newer daemon (API 1.44): the scripts in this repo set `DOCKER_API_VERSION=1.44` on macOS so they work. To fix your shell for other commands, run: `export DOCKER_API_VERSION=1.44` (or add it to `~/.zshrc`).

If the script still says Docker is not responding after Docker Desktop shows "running":

- In Terminal run: `docker context use desktop-linux` then `docker info`. You want "Server:" with version info and no ERROR.
- **Docker menu → Troubleshoot → Restart Docker Desktop**; wait until fully started.
- To see the real daemon error: `tail -50 ~/Library/Containers/com.docker.docker/Data/log/vm/dockerd.log`
- If it still fails: **Troubleshoot → Clean / Purge data** (removes containers/images; often fixes a stuck daemon), then run setup again.
- **Update Docker Desktop** to the latest version (Settings → Software Updates or download from docker.com).
- Last resort: **Troubleshoot → Reset to factory defaults**, or uninstall and reinstall Docker Desktop.

#### “permission denied” when accessing files

- Make sure the workspace directory actually exists.
- Check Docker Desktop File Sharing (step 3).
