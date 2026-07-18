---
type: synthesis
tags: [session-note]
sources: []
updated: 2026-07-18
status: stable
query: "Session note — settings.json drift root-fix (runtime keys) + harvest-reads-disk decision"
---

# Session Note — 2026-07-18 — settings.json Drift Root-Fix + Harvest-Reads-Disk Decision

## What was attempted

Work the standing open threads. Root-fix the recurring `settings.json` drift nag, and settle whether
the harvest "ignoring `.gitignore`" is a bug or the intended design.

## What shipped

- **`setup.ps1` — `model` + `effortLevel` added to `$SettingsRuntimeKeys`.** These are the *only* two
  keys that ever differ between the repo master and the live copy, and both are rewritten at runtime
  (`/model`, the effort toggle). Dropping them from the canonical-JSON compare — the same mechanism
  that already ignores the plugin-hydration keys (`enabledPlugins`, `extraKnownMarketplaces`) — stops
  the SessionStart drift-check / `-Harvest` / audit from flagging `settings.json` every session.
  Resolves the STATUS "root-fix: exclude it from the scan" thread. **Verified:** the `-Harvest`
  dry-run now reports "nothing to harvest" where it previously listed `settings.json` as CHANGED-UP.
  Takes effect immediately — `setup.ps1` runs in place from the repo (not a deployed file), so no
  redeploy is needed for the nag to stop.

## What was decided (no code change)

- **Harvest reading the `~/.claude` disk is intended, not a bug — thread closed.** The workflow is:
  harvest mirrors live disk → repo disk 1:1 (noise and all); `.gitignore` filters the noise at
  **commit/push** (the ship skill stages **by name**). The key fact: `.gitignore` keeps noise out of
  the *git repo*, not out of the *folder* — so the scanner *should* read the disk. The drift alarm is
  self-clearing (harvesting the scratch file re-syncs the two disks) and throttled once/day. Teaching
  the scanner to re-filter what git already filters would duplicate the single source of truth and
  break the disk-1:1 invariant. Supersedes the STATUS "harvest doesn't respect `.gitignore`" thread.

## What was deferred

- Deploy-DOWN still overwrites live `model`/`effortLevel` from the master on `-Force` (rare; a
  merge-instead-of-copy for those two keys is a separate optional fix).
- The `settings.json` **working-tree copy** is still dirty from a prior session's harvest; it is
  excluded from every commit by name. `git checkout -- settings.json` would retire that dance.
- `setup.sh` (Unix) parity must carry the same `$SettingsRuntimeKeys` list when built.

## Open threads

- Harness pass 2; `setup.sh` parity; v1.14.0 backfill note; `s.ship-cc-tlkit` Step 1 wording — all
  unchanged, still open.
- The disk-1:1 / filter-at-commit principle is a promote candidate for a `concepts/` note
  (single-source-of-truth for "what counts as noise"). Flagged, not written.

## Related
- [[../concepts/declarative-intent-over-materialized-state]] — same single-source-of-truth spirit
- [[2026-07-17-session-single-pass-release-flow]] — prior session; flagged the settings.json thread this one closes
