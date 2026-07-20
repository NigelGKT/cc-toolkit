---
type: synthesis
tags: [session-note]
origin: GKT cc-toolkit (wiki brain lint + log restructure, 2026)
sources: []
updated: 2026-07-20
status: stable
query: "Session note — wiki brain lint pass + log.md restructure + brain.base"
---

# Session Note — 2026-07-20 — Wiki Brain Lint + Log Restructure + brain.base

## What was attempted
Health-check the global brain for the first time (contradictions, staleness, orphans,
frontmatter/index/log drift), then act on a follow-up report that the operation log had become
hard to navigate.

## What shipped
- **Lint pass** — 9 findings across contradictions / stale claims / orphans / missing pages /
  frontmatter drift / index drift / log gaps / topic gaps / wikilink hygiene / tag drift. 7 fixed:
  `origin:` added to all 8 `syntheses/` pages; `log.md`'s 07-10 entry got its missing `Session:`
  line; a backfilled log entry recorded [[../harness/session-lifecycle]] +
  [[../harness/hooks-and-permissions]]'s creation (previously unlogged); `index.md` gained a
  Playbooks zone-charter pointer; bare cross-folder wikilinks in the 07-16 synthesis fixed to the
  `../` convention; new concept [[../concepts/harvest-mirrors-disk-filter-at-commit]] promoted (a
  principle prior session notes flagged as a candidate but never wrote).
- **2 findings rejected on review** — the "misfiled playbook" call on
  [[../playbooks/cc-toolkit-deploy-lifecycle]] (harness/README already cross-references it as the
  intentional runbook counterpart to its own architecture note — not drift); the "unconditional
  harvest" staleness claim (verified only 1 synthesis references it, and it's about
  `s.ship-cc-tlkit`'s own wording, already tracked as a STATUS open thread — not a wiki-page defect).
- **Cross-copy drift check** — MD5-checksummed the repo clone against
  `~/.claude/cc-toolkit-wiki-brain`: zero pre-existing drift; the only differences were this
  session's own unharvested edits.
- **`log.md` restructured** — was badly out of order (entries jumped
  07-06→07-10→07-15→07-20→07-18→07-17→07-16×5→07-15); re-sorted to strict newest-first, content
  otherwise untouched.
- **`brain.base` added** — a new Obsidian Base at the wiki root: live sortable/filterable table
  over `type`/`status`/`updated`/`origin`/`tags`, grouped by type, scoped to the 6 content folders.
  `log.md` keeps its own job (append-only event history) since a Base can't reconstruct *why*
  something changed — `README.md` updated to document the split.

## What was deferred
- `s.ship-cc-tlkit`'s Step 1 wording (implies `-Harvest -Force` is unconditional) — already an
  open thread in `STATUS.md`, untouched this session.

## Open threads
- None new.
