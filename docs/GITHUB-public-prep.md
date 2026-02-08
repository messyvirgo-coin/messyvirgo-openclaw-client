# GitHub public-prep checklist (Messy Virgo template)

This file documents the **GitHub-side changes** applied to prepare this repository for going public.

It’s written so you can reuse the same steps for other repositories.

> Repo used as example: `messyvirgo-coin/messyvirgo-openclaw-client`
> Default branch: `main`

## Prerequisites

- Install GitHub CLI: `gh`
- Authenticate:
  - `gh auth login`
  - Confirm: `gh auth status -h github.com`
- Ensure you have **admin** permissions on the target repo.

## 1) Protect the default branch (`main`)

Goal: by default, changes land via PRs with guardrails; optionally allow admins to bypass when needed.

Applied settings:

- Require pull requests before merging
- Require 1 approving review
  - Dismiss stale approvals on new pushes
  - Require CODEOWNERS review
- Require conversation resolution
- Require linear history
- Enforce for admins too (optional; see below)
- Disallow force pushes
- Disallow branch deletion

Command used (via REST API with `gh api`):

```bash
gh api -X PUT repos/<OWNER>/<REPO>/branches/main/protection --input - <<'JSON'
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": true
}
JSON
```

### Admin bypass (Option B)

If you want **repo/org admins** to be able to:

- push directly to `main`, and/or
- merge PRs without required approvals

then turn OFF admin enforcement:

```bash
gh api -X DELETE repos/<OWNER>/<REPO>/branches/main/protection/enforce_admins
```

Verify:

```bash
gh api repos/<OWNER>/<REPO>/branches/main/protection/enforce_admins
```

Expected: `"enabled": false`

For `messyvirgo-coin/messyvirgo-openclaw-client`, this is the mode we ended up using (admins can bypass).

### Optional follow-up: require CI checks

We did **not** set `required_status_checks` yet, because GitHub can only require checks after they exist and have run at least once on the branch.

After CI is merged and has produced check-runs, set required checks (example):

```bash
gh api -X PATCH repos/<OWNER>/<REPO>/branches/main/protection/required_status_checks --input - <<'JSON'
{
  "strict": true,
  "checks": [
    { "context": "ShellCheck" },
    { "context": "Bash syntax" }
  ]
}
JSON
```

Note: the exact `context` names must match what GitHub reports for your workflow runs.

## 2) Repo settings (housekeeping)

Applied settings:

- **Automatically delete head branches** after merge: enabled
- Wiki: disabled
- Projects: disabled

Command used:

```bash
gh api -X PATCH repos/<OWNER>/<REPO> --input - <<'JSON'
{
  "delete_branch_on_merge": true,
  "has_wiki": false,
  "has_projects": false
}
JSON
```

## 3) Topics (discoverability)

Applied topics:

- `openclaw`
- `docker`
- `docker-compose`
- `sandbox`
- `local-development`
- `shell-scripts`

Command used:

```bash
gh api -X PUT repos/<OWNER>/<REPO>/topics \
  -H "Accept: application/vnd.github+json" \
  --input - <<'JSON'
{
  "names": [
    "openclaw",
    "docker",
    "docker-compose",
    "sandbox",
    "local-development",
    "shell-scripts"
  ]
}
JSON
```

## 4) Forking policy note (org-level)

We attempted to enable forking while the repo is **private**:

```bash
gh api -X PATCH repos/<OWNER>/<REPO> --input - <<'JSON'
{
  "allow_forking": true
}
JSON
```

GitHub returned:

- `422`: “This organization does not allow private repository forking”

Meaning: this is controlled by **organization policy** for private repos.

Once the repo is public, forking is generally available by default; if you still want to explicitly set it, re-run the command after making the repo public.

## 5) Final step: make repo public

Once you’ve:
- removed secrets
- added collateral files
- merged CI + templates
- ensured branch protection is in place

you can switch visibility:

```bash
gh repo edit <OWNER>/<REPO> --visibility public
```

Or do it in GitHub UI:
Repo → Settings → General → Danger Zone → Change repository visibility.

