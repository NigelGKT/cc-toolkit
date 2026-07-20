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

- **Uncommitted, ready to ship as v1.23.0 — first wiki-brain lint pass + log.md restructure + brain.base.**
  - **Lint pass on `cc-toolkit-wiki-brain`** — 9 findings, 7 fixed (missing `origin:` on all 8
    syntheses, a missing log `Session:` line, a backfilled log entry for harness pass 2, an index
    pointer, a wikilink-style fix, one new promoted concept); 2 rejected on review (a "misfiled
    playbook" call that turned out to be intentional design, and an "unconditional harvest" claim
    that's actually about `s.ship-cc-tlkit`'s own wording, not a wiki defect — see open threads).
    Cross-checked the repo clone against `~/.claude/cc-toolkit-wiki-brain` by MD5: zero pre-existing
    drift found.
  - **`log.md` re-sorted** to strict newest-first order (previously scattered out of sequence).
  - **`brain.base` added** — a live, sortable/filterable Obsidian Base table over every page's
    `type`/`status`/`updated`/`origin`/`tags`. `log.md` stays the append-only event record; the Base
    is a current-state view, not a replacement.
- **Prior: v1.22.0** — Obsidian vault config fully tracked (`app.json`/`appearance.json`/
  `core-plugins.json`/`workspace.json` alongside `graph.json`); repo-vs-harvest workflow split
  confirmed, not collapsed. Shipped.
- **Before that: v1.21.0** — harness pass 2 (2 new self-doc pages) + `setup.sh` parity (incl. a real
  `set -e`/nested-pipeline bug fix, found by actually executing the script) + v1.14.0 session-note
  backfill. Run `git log` for the full commit trail.

## Next step

- **Ship v1.23.0** via `/s.ship-cc-tlkit`.

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
