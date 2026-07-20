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

- **Uncommitted, ready to ship as v1.24.0 — 2 new refactor/dedup playbooks + s.wrap-up promotion auto-apply.**
  - **New playbooks**: `behaviour-preserving-refactor-workflow` (tiered refactor loop — recon the
    live counterpart, re-verify stale audits, per-item equivalence harness, human gate, merge
    boundaries; distilled from the I06 three-tier engine refactor) and
    `prove-empty-diff-before-consolidating` (upstream/downstream reachability checklist before
    merging diverged duplicates; distilled from BUG-W9a). Both Propex-origin, scrubbed.
  - **`s.wrap-up` Part C** — concept/playbook promotions now **applied on the single confirmation**
    (writes the page + index + log entry) instead of staying flag-only for manual follow-up.
    Code/skill/CLAUDE.md promotions still stay flag-only. Codifies the pattern both playbooks above
    already used.
  - **`brain.base`** — minor formatting cleanup + default sort by `updated` (DESC).
- **Prior: v1.23.0** — wiki-brain lint pass (9 findings, 7 fixed), `log.md` re-sorted newest-first,
  `brain.base` added. Shipped (`e998b35`).
- **Before that: v1.22.0** — Obsidian vault config fully tracked; repo-vs-harvest workflow split
  confirmed, not collapsed. Shipped. Run `git log` for the full commit trail.

## Next step

- **Ship v1.24.0** via `/s.ship-cc-tlkit`.
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
