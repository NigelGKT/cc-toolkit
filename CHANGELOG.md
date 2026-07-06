# Changelog

All notable changes to the GKT cc-toolkit. Versioning is `major.minor`.

## [1.3.0] — 2026-07-06

### Added
- **`brain/`** — the global brain: an `s.wiki` vault of cross-project, distilled patterns and
  client-agnostic lessons, deployed to `~/.claude/brain/` on every machine. Seeded with three
  pattern-concepts (`fifo-vs-vwap-cost-basis`, `convert-at-edge-display-lens`,
  `cost-layer-as-derived-view`) promoted from the Propex PTA wiki — scrubbed to patterns with
  `origin:` provenance in frontmatter. Mirrors PTA's schema + graph colour-group system.
- **`deployment/windows/cleanup.ps1`** + **`deployment/unix/cleanup.sh`** — clean-exit scripts.
  Dry-run by default; `-Force` removes `~/.claude` (backup first) and unsets `ANTHROPIC_API_KEY`;
  `-Force -NoBackup` is the client-exit mode that leaves no residue.

### Changed
- **`setup.ps1` / `setup.sh`** now deploy `brain` as a toolkit item. `playbooks/` is folded into
  the brain (`brain/playbooks/`); the old top-level `playbooks/` is superseded (delete manually).
- **`s.wrap-up` Part C** now routes promote candidates to `brain/concepts/` and `brain/playbooks/`,
  with a scrub-and-record-`origin:` step.

### Notes
- Provenance `origin:` names real clients and the brain deploys everywhere; the cross-engagement
  confidentiality question is deliberately deferred until it's a live concern.

## [1.2.0] — 2026-07-05

### Added
- **`deployment/unix/setup.sh`** — Linux/macOS port of `setup.ps1`. Same audit-or-deploy
  behaviour (clean → deploy; existing config → audit; `--force` → backup then deploy),
  CRLF-normalised hashing, and secret exclusions. Node.js is auto-installed via **nvm**
  (`nvm install --lts` — no sudo, self-sourced for the run); Claude Code via `npm install -g`.
  Unblocks the VPS track.
- **Auto-install in `setup.ps1`** — a missing Node.js is installed via winget and Claude Code
  via npm, so a fresh Windows machine self-provisions instead of only reporting what's missing.

### Notes
- `cleanup.ps1` / `cleanup.sh` remain deferred until the first client-machine clean-exit need.

## [1.1.0] — 2026-06-25

### Fixed
- **`setup.ps1` audit was line-ending-sensitive.** It compared files with a raw byte
  hash (`Get-FileHash`), so a fresh clone checked out as CRLF read as 13 false conflicts
  against an LF working copy. The audit now normalises line endings before hashing
  (binary files fall back to a raw hash), so it reports real content drift only.

### Added
- **`.gitattributes`** (`* text=auto eol=lf`) — fresh clones check out LF, matching the
  authored files, so byte-diffs and the audit stay consistent across machines.

### Notes
- Surfaced by the Step 7 acid test: deploying from a fresh clone produced a wall of
  false conflicts that were purely CRLF vs LF.

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
