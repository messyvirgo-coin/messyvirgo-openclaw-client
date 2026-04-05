# Contributing to OpenClaw

Thanks for your interest in contributing to OpenClaw.

Contributions are welcome, but please note:

- This repo is public and open to PRs, **but not every PR will be merged**.
- Maintainers keep final say on scope, design, and what gets shipped.
- Support is **best-effort** only.

## Ground rules

- **Be respectful**: follow the [Code of Conduct](./CODE_OF_CONDUCT.md).
- **Keep it public-safe**: do not include secrets, tokens, personal data, private links, or confidential information.
- **Keep PRs focused**: one change-set per PR when possible.
- **Prefer portability**: scripts should work on the target OS/shell and avoid surprising side effects.

## What kinds of contributions we welcome

- Fixes for installation and UX issues in `docs/`, `openclaw-secure/`, or `openclaw-raw/`
- Bug fixes, especially around Docker networking differences across Linux and macOS
- Improvements to hardening without breaking usability
- New platform support, with clear documentation

## Contribution boundaries

- The maintainers may decline changes that increase maintenance burden, reduce security, or expand scope.

## Pull request checklist

- Explain intent: what problem does this solve?
- Add or update docs if the user workflow changes.
- Test on at least one platform and describe what you ran.
- Double-check you did **not** commit `.env`, tokens, or local paths.

## Maintainers

- `@messy-michael`
- `@MessyFranco`
