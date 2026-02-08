# Contributing to messyvirgo-openclaw-client

Thanks for your interest in contributing to Messy Virgo.

This repository is a **small helper/wrapper** that runs [OpenClaw](https://github.com/openclaw/openclaw) locally in Docker (Linux/macOS) to provide a sandbox-style environment.

Contributions are welcome (including Windows support), but please note:

- This repo is public and open to PRs, **but not every PR will be merged**.
- Maintainers keep final say on scope, design, and what gets shipped.
- Support is **best-effort** only (see [SUPPORT.md](./SUPPORT.md)).

## Ground rules

- **Be respectful**: follow the [Code of Conduct](./CODE_OF_CONDUCT.md).
- **Keep it public-safe**: do not include secrets, tokens, personal data, private links, or confidential information.
- **Keep PRs focused**: one change-set per PR when possible.
- **Prefer portability**: scripts should work on the target OS/shell and avoid surprising side effects.

## What kinds of contributions we welcome

- Fixes for installation/UX issues in `docs/` or `scripts/`
- Bug fixes (especially around Docker networking differences across Linux/macOS)
- Improvements to hardening (without breaking usability)
- New platform support (e.g. Windows scripts), with clear documentation

## Contribution boundaries (important)

- This repo provides a local wrapper. It is **not** the upstream OpenClaw project.
  - Upstream issues/feature requests should generally go to OpenClaw.
- The maintainers may decline changes that increase maintenance burden, reduce security, or expand scope.

## Pull request checklist

- Explain intent: what problem does this solve?
- Add/update docs if the user workflow changes.
- Test on at least one platform (Linux or macOS) and describe what you ran.
  - If you can’t test, say so explicitly.
- Double-check you did **not** commit `.env`, tokens, or local paths.

## Maintainers

- `@messy-michael`
- `@MessyFranco`
