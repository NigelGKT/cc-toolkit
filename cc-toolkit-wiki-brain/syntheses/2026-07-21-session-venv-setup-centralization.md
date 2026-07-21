---
type: synthesis
tags: [session-note]
sources: []
updated: 2026-07-21
status: stable
query: "Session note — venv-setup script folded into cc-toolkit, README staleness fix"
---

# Session Note — 2026-07-21 — venv-setup Centralization

## What was attempted
Fold the standalone `pyvenv_scripts`/`NigelGKT/scripts` project's Python venv-setup tool
(`new-pyproject.ps1`) into `cc-toolkit` as native tooling, instead of a separately-referenced
project — plus fix a stale `README.md` found along the way.

## What shipped
- **`README.md` corrected** — the documented workflow had drifted stale: it still said "build
  locally in `~/.claude` first, then harvest up" when the toolkit's actual current convention
  (per `cc-toolkit-deploy-lifecycle.md`'s own invariant) is "prefer curating in the repo clone."
  Also fixed the "What's inside" tree, which was missing `cc-toolkit-wiki-brain/`, `STATUS.md`,
  `CHANGELOG.md`, two of four deployment scripts, and three of five skills, and showed a
  `playbooks/` folder at the wrong (top) level.
- **New `scripts/` top-level folder** — the standing home for reusable, cross-project utility
  scripts (as opposed to `deployment/`, which is toolkit-*self*-maintenance only). Holds
  `new-pyproject.ps1`, relocated here with an updated header comment (usual invocation is now
  via the skill, not a hand-typed path).
- **New `skills/s.venv-setup/SKILL.md`** — thin wrapper; locates `scripts/new-pyproject.ps1`
  (two levels up from its own injected base directory, since `scripts/` and `skills/` are
  sibling deployed folders) and runs it against the current project folder.
- **Deploy contract updated** — added `'scripts'` to `$ToolkitItems` in both
  `deployment/windows/setup.ps1` and `TOOLKIT_ITEMS` in `deployment/unix/setup.sh` (in lockstep,
  per the existing invariant), so the new folder actually rides to every machine on deploy.
- **New playbook** — `cc-toolkit-wiki-brain/playbooks/venv-setup-workflow.md`, distilled from
  the old project's `PY_VENV_WORKFLOW.md` (import-scan-driven sync, one-package-at-a-time
  install to isolate PyPI-name mismatches, delete-`.venv`-and-rerun on breakage).
- **`harness/skills-catalog.md` updated** — added the `s.venv-setup` entry, bumped the skill
  count language (four → five user-authored skills).

## What was deferred
- Shipping (this pass, via `/s.ship-cc-tlkit`) and a post-deploy smoke test of `/s.venv-setup`
  against a real project (the Bursa derivatives scraper) are the immediate next steps, tracked
  in `STATUS.md` rather than here.
- Deleting the old `pyvenv_scripts` folder and/or its `NigelGKT/scripts` GitHub repo is left to
  the user, manually, whenever — nothing there was touched or removed this session. Verified
  first that its wiki brain held no undistilled knowledge (it was empty scaffolding only).

## Open threads
- The outer `pyvenv_scripts/.git` is a stray, remote-less repo (per that project's own
  `STATUS.md`); the real history lives in the nested `scripts/` folder's `NigelGKT/scripts`
  remote. Two different repos, two different disposals, if the user chooses to clean up.
