---
type: synthesis
tags: [session-note]
sources: []
updated: 2026-07-15
status: stable
query: "Session note — cc-toolkit harvest systematization (local→repo)"
---

# Session Note — 2026-07-15 — Harvest Systematization (local→repo)

## What was attempted
Close the asymmetry in `setup.ps1`: it only ever pushed the repo DOWN to `~/.claude`, leaving
the *pull local work UP* direction manual and forgettable — even though the real workflow is
land a change in `~/.claude` first, then harvest it into cc-toolkit. Make local→repo a
first-class, self-reminding direction (detect + act + remind).

## What shipped
- **`setup.ps1 -Harvest`** (new) — the file inverse of deploy: lists **NEW-UP** (machine-only) +
  **CHANGED-UP** (edited locally, newer than repo) toolkit files; dry-run by default, `-Force`
  copies them into the repo working tree. Skips repo-newer files; never harvests secrets.
- **Direction-aware audit** — the old single `CONFLICTS` bucket now splits into **LOCAL NEWER**
  (harvest up) vs **REPO NEWER** (deploy down) by `LastWriteTime`; content-hash stays
  authoritative for *whether* files differ. Shared `Get-ToolkitDrift` classifier backs the
  audit, `-Harvest`, and `-Check`.
- **`setup.ps1 -Check` + `drift-check.ps1` (new) + a SessionStart hook** — a silent, once/day,
  throttled nudge when local files aren't harvested yet. Opt-in per machine via
  `CC_TOOLKIT_HOME`; no-ops until set. Hook uses a `-File` wrapper (not inline `-Command`) so
  it's robust to how the harness shell quotes it. `drift-check.ps1` added to the deploy manifest.
- **settings.json semantic compare (v1.13.0 fix)** — plugin hydration rewrites the deployed
  `settings.json` (appends `enabledPlugins`/`extraKnownMarketplaces` + reorders keys), which
  made the drift check false-positive after every deploy. Now compared via canonical JSON (drop
  the runtime keys, sort keys recursively, hash); real changes still detected, non-JSON falls
  back to the raw hash.
- **Docs** — `README.md` (files-harvest + drift-reminder sections, direction-aware audit
  buckets), `CHANGELOG.md` v1.12.0 + v1.13.0, and a note in `fde-toolkit/STATUS.md`.
- Committed + pushed to `origin/main`: `b91c510` (v1.12.0) and `294d7ba` (v1.13.0). Deployed to
  this machine; `CC_TOOLKIT_HOME` set; audit reads 36/36 in sync.

## What was deferred
- **Unix `setup.sh` parity** — the new flags are Windows-only; the VPS track needs the parallel
  port (mechanical follow-on).
- **Three-tier memory architecture rollout** — CLAUDE.md + STATUS.md + wiki brain across all 7
  project folders; fully designed, parked. Plan: `~/.claude/plans/1-yeap-put-it-concurrent-charm.md`.

## Open threads
- **Promote candidate (not yet filed):** the reusable pattern behind this session — *a synced
  local↔source system needs a harvest-UP path and drift detection, not just deploy-DOWN; and the
  "have I synced yet?" state is inherently per-machine.* Complements
  [[../concepts/declarative-intent-over-materialized-state]]. Promote to `concepts/` (scrubbed)
  on confirmation.
