# Changelog

All notable changes to the GKT cc-toolkit. Versioning is `major.minor`.

## [1.0.0] — 2026-06-25

First consolidated, deployable release. The toolkit is now the single source of truth
for `~/.claude` and can be deployed to any Windows machine.

### Added
- **`CLAUDE.md`** — global operating contract (the "Mr Nigel" identity and working style).
- **`settings.json`** — global Claude Code preferences.
- **`skills/s.wiki/`** — Obsidian-compatible knowledge wiki skill (source/entity/concept/synthesis page types, templates, lint checks).
- **`skills/s.wrap-up/`** — end-of-session ritual; now includes **Part C — Promote**, which flags generalizable lessons for the toolkit.
- **`playbooks/`** — home for client-agnostic lessons distilled from project work.
- **`deployment/windows/setup.ps1`** — audit-or-deploy installer:
  - Clean machine → deploys the toolkit.
  - Existing config → AUDIT MODE (in-sync / conflicts / harvest candidates / would-be-added); changes nothing until reviewed.
  - `-Force` → deploys over an existing config after a lightweight timestamped backup.
  - Never touches secrets (`.credentials.json`, `settings.local.json`) or runtime state.
- **`README.md`** — overview + Windows deployment runbook.
- **`.gitignore`** — excludes secrets, runtime state, and OS/editor noise.

### Notes
- Flat layout: each top-level item maps 1:1 into `~/.claude`.
- API key is never stored in the repo — set `ANTHROPIC_API_KEY` from a password manager at deploy time.
- Unix deploy script (`deployment/unix/setup.sh`) and a guarded `cleanup.ps1` are deferred until needed.
