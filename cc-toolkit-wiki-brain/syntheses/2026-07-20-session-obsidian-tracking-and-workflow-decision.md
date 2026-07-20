---
type: synthesis
tags: [session-note]
origin: GKT cc-toolkit (obsidian tracking + workflow decision, 2026)
sources: []
updated: 2026-07-20
status: stable
query: "Session note — Obsidian vault fully tracked + repo-vs-harvest workflow decision"
---

# Session Note — 2026-07-20 — Obsidian Tracking + Workflow Split Decision

## What was attempted

Two small follow-ons from the v1.21.0 close-out discussion: fix the Obsidian `.gitignore` scope
(a prior session had drawn the "real settings vs. volatile state" line too narrowly), and settle
whether "edit the repo directly" vs. "edit `~/.claude` then harvest" should collapse to one path.

## What shipped

- **`.gitignore`** — removed the `**/.obsidian/*` / `!**/.obsidian/graph.json` block entirely.
  `app.json`, `appearance.json`, `core-plugins.json`, and `workspace.json` are now tracked
  alongside `graph.json`. Deliberate choice, not an oversight: `workspace.json` is genuine
  session state (open panes, scroll position) and will diff more often than the others — accepted
  in exchange for a fresh clone opening the wiki with the same workspace layout on every machine.
- **`STATUS.md`** — records the workflow-split decision (below) so it isn't re-litigated.

## What was decided (no code change)

- **Keep both editing workflows — do not collapse to `~/.claude`-first.** Considered forcing every
  session through "edit `~/.claude` → harvest → ship" for a single consistent mental model.
  Decided against: editing the repo directly (this session's pattern, and every prior ship
  session's) is the *documented-preferred* path for deliberate toolkit-development work — see
  `wiki-schema.md`'s existing "prefer curating [the repo]... local editing supported via
  `-Harvest`." It skips a redundant harvest round-trip entirely, and the repo's own git working
  tree is a free safety net (`git diff`/`status`) that editing `~/.claude` directly doesn't have
  until harvest actually happens. The `~/.claude`-then-harvest path remains correct for its actual
  use case: incidental toolkit-relevant edits picked up during unrelated project sessions, where
  the repo isn't in reach.

## What was deferred

Nothing new — same open threads as v1.21.0 (cross-platform hook wiring, `settings.json`
working-tree noise, deploy-clobber of `model`/`effortLevel`, `s.ship-cc-tlkit` Step 1 wording).

## Open threads

None new this session.

## Related
- [[../wiki-schema]] — the existing repo-vs-harvest language this session confirmed rather than changed
- [[2026-07-18-session-settings-drift-runtime-keys]] — same "confirm existing design, no code change" shape as the harvest-reads-disk decision
