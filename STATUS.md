# cc-toolkit — Live Status (working tier)

> **Read this first when picking up cc-toolkit.** The working-memory tier: where we are right now
> and what's next — **state + intent only**. History, SHAs, and commit/push state live in `git`
> (`git log`, `git status`), not here; per-session synthesis and the changelog archive live in
> `cc-toolkit-wiki-brain/syntheses/`. This project's `CLAUDE.md` **is** the global operating
> contract (deployed to `~/.claude`), so it carries no project pointer — this file is it.
> Last updated: 2026-07-21.
>
> *(Scope split: this file = cc-toolkit's live working state. Meta-roadmap / phase direction lives
> in the `fde-toolkit` brain.)*

## Where we are

- **Uncommitted, ready to ship as v1.25.0 — venv-setup centralized into cc-toolkit + README fixed.**
  - **`new-pyproject.ps1` folded in** from the standalone `pyvenv_scripts`/`NigelGKT/scripts`
    project — now lives at `scripts/new-pyproject.ps1`, a new top-level home for reusable
    cross-project utility scripts (distinct from `deployment/`, which is toolkit self-maintenance
    only). New `skills/s.venv-setup/` wraps it. `scripts` added to the deploy contract
    (`ToolkitItems`/`TOOLKIT_ITEMS`) in both `setup.ps1` and `setup.sh`.
  - **New playbook** — `venv-setup-workflow` (import-scan-driven requirements.txt sync, gotchas).
    `harness/skills-catalog.md` updated with the new skill entry.
  - **`README.md` corrected** — was stale (still described the superseded "build locally, harvest
    up" default and an inaccurate folder tree). Now states "prefer the repo clone" as the actual
    current default and matches the real layout.
  - Old `pyvenv_scripts` project left untouched — its wiki brain held no undistilled knowledge
    (empty scaffolding only). Disposal (two separate repos, one remote-less) is a manual user
    decision, not part of this change.
- **Prior: v1.24.0** — 2 new refactor/dedup playbooks + `s.wrap-up` Part C promotion auto-apply.
  Shipped (`3af2d97`), followed by a small unversioned fix (`88133c7`: redirect `-Force` deploy
  backups to `~/.claude backups/`). Run `git log` for the full trail.

## Next step

- **Ship v1.25.0** via `/s.ship-cc-tlkit` (in progress).
- **Smoke-test `/s.venv-setup`** against a real project once deployed (e.g. re-run against the
  Bursa derivatives scraper, which already has a `.venv`) to confirm the skill's path resolution
  works end-to-end, not just the standalone script.
- **Follow-up (flagged, not started):** audit whether "prefer the repo clone" should remain the
  *stated default* in `wiki-schema.md`/`cc-toolkit-deploy-lifecycle.md` — recent practice (both
  playbooks above, the new `s.wrap-up` write path) increasingly authors `~/.claude`-first, and the
  2026-07-20 13:00 decision already chose to keep both workflows rather than collapse to one.

## Open threads

- **`s.ship-cc-tlkit` Step 1 wording** — it implies `-Harvest -Force` is unconditional. When a
  session authors **directly in the repo** (as several recent sessions' own did), harvest is a
  correct no-op and the dry-run says so; forcing it would only import noise. The skill should state
  that explicitly.
- **Cross-platform `SessionStart` hook wiring** — the hook command is hardcoded to
  `powershell -NoProfile -File ~/.claude/drift-check.ps1` in the one shared `settings.json`, so
  even with `setup.sh --check` now built, nothing auto-invokes it on a Mac/Linux machine. Needs a
  `drift-check.sh` plus a way for the hook to pick the right script per OS — a real design question,
  not a mechanical port. Zero live impact today (Windows-primary); found during the v1.21.0
  `setup.sh` parity work.
- **`settings.json` working-tree copy still dirty** — pre-existing unrelated drift (key reorder +
  runtime keys), excluded from every commit by name. `git checkout -- settings.json` would clear it
  outright; low priority since it never rides along.
- **Deploy-DOWN still overwrites live `model`/`effortLevel`** from the master on `-Force`/`--force`
  (both Windows and now Unix) — rare, and arguably fine; a merge-instead-of-copy for those two keys
  is a separate optional fix. Noted since v1.20.0.

## Reference

- Global brain: `cc-toolkit-wiki-brain/` (rides to every machine via deploy) — dual charter:
  transferable knowledge (`concepts/`/`playbooks/`) + self-documentation (`harness/`, `incidents/`).
- Lifecycle: `/s.ship-cc-tlkit` conducts the round-trip; the primitives underneath are `setup.ps1`
  (`-Force` deploy down, `-Harvest` copy up, `-Check` drift). Full runbook:
  `cc-toolkit-wiki-brain/playbooks/cc-toolkit-deploy-lifecycle.md`.

---

*History → `git`. Synthesis/decisions → `cc-toolkit-wiki-brain/`. This file is state + intent only —
keep it short and current.*
