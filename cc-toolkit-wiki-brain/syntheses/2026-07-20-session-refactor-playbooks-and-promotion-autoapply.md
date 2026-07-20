---
type: synthesis
tags: [session-note]
sources: []
updated: 2026-07-20
status: stable
query: "Session note — refactor/dedup playbooks + s.wrap-up promotion auto-apply"
---

# Session Note — 2026-07-20 — Refactor/Dedup Playbooks + Promotion Auto-Apply

## What was attempted

Promote two refactor/consolidation lessons from Propex Trading sessions into the global brain,
and update `s.wrap-up` so prose promotions land automatically on confirmation instead of
staying flag-only for the user to action by hand.

## What shipped

- **New playbook** `playbooks/behaviour-preserving-refactor-workflow.md` — tiered refactor loop
  (risk-tiered audit, live-counterpart recon/isolation, stale-audit re-verification, per-item
  behavioural-equivalence harness, human gate for un-harnessable surfaces, merge/push
  boundaries), distilled from the I06 three-tier engine refactor (sessions 2026-07-04/07-06/
  07-20).
- **New playbook** `playbooks/prove-empty-diff-before-consolidating.md` — upstream/downstream
  reachability checklist before merging diverged duplicate code, distilled from the BUG-W9a
  de-dup finding.
- `index.md` + `log.md` updated for both promotions (two `promote` entries).
- **`skills/s.wrap-up/SKILL.md`** — Part C's promotion step now **applies** concept/playbook
  candidates on the single confirmation (writes the distilled page + index + log entry) instead
  of only flagging them for manual follow-up; code/skill/CLAUDE.md promotions still stay
  flag-only (they need real implementation, not a distilled note). Codifies the pattern both
  playbooks above already used.
- `brain.base` — minor formatting cleanup (stray blank lines, quote style) + added a default
  sort by `updated` (DESC) to the table view.
- `.obsidian/workspace.json` — routine pane/tab state from continued vault use this session
  (tracked by design since v1.22.0; not itself a content change).

## What was deferred

- `settings.json` — pre-existing runtime-key drift (plugin hydration + `effortLevel` toggle),
  excluded by name from the commit per the standing convention (already an open thread in
  `STATUS.md`).
- **Harvest-workflow default audit** — whether "prefer the repo clone" should remain the stated
  default in `wiki-schema.md`/`cc-toolkit-deploy-lifecycle.md`, given how much recent work
  (both playbooks here, the new `s.wrap-up` write path) lands `~/.claude`-first. Explicitly
  parked as a separate follow-up, not touched this session.

## Open threads

- Carried from `STATUS.md`: `s.ship-cc-tlkit` Step 1 wording implies `-Harvest -Force` is
  unconditional; should state the no-op case explicitly.
- Carried: cross-platform `SessionStart` hook wiring (no `drift-check.sh` yet).
- Carried: deploy-DOWN still overwrites live `model`/`effortLevel` on `-Force`.
- New: the harvest-workflow default audit noted above.
