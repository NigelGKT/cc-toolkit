# cc-toolkit — Live Status (working tier)

> **Read this first when picking up cc-toolkit.** The working-memory tier: where we are right now
> and what's next — **state + intent only**. History, SHAs, and commit/push state live in `git`
> (`git log`, `git status`), not here; per-session synthesis and the changelog archive live in
> `cc-toolkit-wiki-brain/syntheses/`. This project's `CLAUDE.md` **is** the global operating
> contract (deployed to `~/.claude`), so it carries no project pointer — this file is it.
> Last updated: 2026-07-20.
>
> *(Scope split: this file = cc-toolkit's live working state. Meta-roadmap / phase direction lives
> in the `fde-toolkit` brain.)*

## Where we are

- **Uncommitted, ready to ship as v1.22.0 — Obsidian vault fully tracked; workflow split confirmed.**
  - **Obsidian settings now ride to every machine.** `.gitignore`'s old `.obsidian/*` exclusion
    (everything ignored except `graph.json`) is removed — `app.json`, `appearance.json`,
    `core-plugins.json`, and `workspace.json` are now tracked too, so a fresh clone opens the wiki
    with the same workspace layout, not a blank one. Deliberate tradeoff accepted: `workspace.json`
    is genuine session state and will show as changed more often than the others; worth it for
    cross-machine consistency.
  - **Workflow split decision (no code change) — keep both paths.** Discussed collapsing to a
    single "edit `~/.claude` → harvest → ship" workflow for consistency, since that's what thread
    #2's "disk mirrors disk" framing implied was the only path. Decided **against** collapsing it:
    editing the repo directly (this session's own pattern) is the documented-preferred path for
    deliberate toolkit-development sessions — it skips harvest entirely since the repo already is
    the source of truth, and the repo's own git working tree is a free safety net while editing.
    Editing `~/.claude` + harvesting stays the right path for incidental edits picked up during
    unrelated project sessions, where the repo isn't in reach. Confirms `wiki-schema.md`'s existing
    "prefer curating [the repo]... local editing supported via `-Harvest`" language rather than
    changing it — recorded here so it isn't re-litigated as an inconsistency later.
- **Prior: v1.21.0** — harness pass 2 (2 new self-doc pages) + `setup.sh` parity (incl. a real
  `set -e`/nested-pipeline bug fix, found by actually executing the script) + v1.14.0 session-note
  backfill. Run `git log` for the full commit trail.

## Next step

- **Ship v1.22.0** via `/s.ship-cc-tlkit`.

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
