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

#### “permission denied” when accessing files

- Make sure the workspace directory actually exists.
- Check Docker Desktop File Sharing (step 3).
