---
type: concept
tags: [sync, filtering, single-source-of-truth, deploy, harvest]
origin: GKT cc-toolkit (harvest/deploy scanner design, 2026)
sources: []
updated: 2026-07-20
status: stable
---

# Harvest Mirrors Disk, Filters at Commit

A state-mirroring scanner should read its source **1:1, noise and all** — filtering belongs
at the point of commit/publish, not at the point of scan.

## The principle
When a tool mirrors a live filesystem (or any authoritative source) into a versioned copy,
it's tempting to make the scanner "smart" — teach it to skip files an exclusion list (like
`.gitignore`) already marks as noise. Resist that: the exclusion list's job is to keep noise
*out of the versioned artifact*, not out of the *scan*. Two different filters, two different
jobs — collapsing them duplicates the single source of truth for "what counts as noise" and
risks the two definitions drifting apart.

Split the pipeline into two independent stages:
1. **Scan** — read the live source completely, unfiltered. The scan's only job is an accurate
   mirror.
2. **Stage/commit** — apply the exclusion rule exactly once, at the boundary where content
   actually enters the versioned artifact (stage-by-name, commit, publish).

## Why it matters
- **One filter, one place** — an exclusion rule duplicated into the scanner and the commit
  boundary can silently diverge; keeping it in one place means it can't.
- **The scan stays a trustworthy mirror** — a "smart" scanner that pre-filters can no longer
  answer "what's actually different from the source," which is often the more useful
  question (drift detection, audits) than "what would get committed."
- **Alarm fatigue has a single fix point** — if the scan flags something that should never be
  committed, the fix is a staging-time exclusion, not a scanner-side special case.

## Transfer note
Reach for this whenever a sync/harvest/backup/ETL scanner starts accumulating special-case
logic to "not see" files an existing exclusion list already governs (`.gitignore`,
allow/deny lists, tag filters). The exclusion list already has a canonical enforcement point
downstream — extend the filter there, and let the scanner keep reporting the unfiltered
truth.

## Related
- [[../playbooks/cc-toolkit-deploy-lifecycle]] — the harvest/stage-by-name mechanics this
  pattern was drawn from
- [[declarative-intent-over-materialized-state]] — same single-source-of-truth spirit applied
  to what gets versioned at all

## Sources
- Derived from the cc-toolkit harvest/`.gitignore` design decision (2026-07-18).
