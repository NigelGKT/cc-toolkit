---
type: synthesis
tags: [session-note, backfilled]
origin: GKT cc-toolkit (three-tier memory architecture, 2026)
sources: []
updated: 2026-07-19
status: stable
query: "Session note — three-tier memory architecture (v1.14.0), backfilled from git history 2026-07-19"
---

# Session Note — 2026-07-15 — Three-Tier Memory Architecture (v1.14.0)

> **Backfilled 2026-07-19** from commit `2378a73` — this note was never written live (the gap
> between the 2026-07-10 and 2026-07-15 notes skipped v1.14.0 entirely). Reconstructed from the
> commit diff and message, not from session memory.

## What was attempted

Give cc-toolkit itself the three-tier memory convention (contract / working memory / long-term
brain) that later shipped to other projects — split by rate-of-change, not topic.

## What shipped

- **Global `CLAUDE.md` — `## Memory architecture` contract.** Three tiers: `CLAUDE.md` (stable
  rules, rarely changes), `STATUS.md` (current version/active task/next step, every session),
  wiki brain (domain knowledge, slow/accretive). Plus an ownership split (operator facts →
  harness memory; transferable knowledge → global brain; per-project knowledge → that project's
  brain) and a DRY rule: the contract lives once, globally — a project `CLAUDE.md` carries only
  thin pointers, never restates it.
- **`skills/s.wiki`** — Bootstrap now scaffolds `STATUS.md` at the project root (from a new
  `templates/status.md`) and appends a thin `## Memory` pointer to `CLAUDE.md`, wiring the
  three-tier convention into every future wiki bootstrap. Ingest gained an explicit **scope
  boundary**: a project brain holds domain knowledge only — operator facts, transferable
  patterns, and volatile "where are we" state are explicitly routed elsewhere, not ingested.
- **`skills/s.wrap-up`** — orientation now reads `STATUS.md` if present; the write stage splits
  volatile state (→ `STATUS.md`) from stable edits (→ `CLAUDE.md`); the re-anchor line now
  prefers `STATUS.md` over the wiki note or `CLAUDE.md`.
- **cc-toolkit's own `STATUS.md`** — the repo adopted its own convention as its first real
  instance.

## What was deferred

Per the freshly-written `STATUS.md`'s own "Pending / open threads" section at the time:
- **`settings.json` harvest decision** — local `effortLevel: xhigh` vs repo `high`, flagged as
  undecided.
- **`setup.sh` parity** for `-Harvest`/`-Check` — flagged as a mechanical Unix follow-on.

## Open threads

Both deferred items above sat open for almost the entire time between v1.14.0 and today. They
were finally closed in the 2026-07-18/19 sessions: the settings-drift decision resolved as a
root-cause fix (runtime keys excluded from comparison — see
[[2026-07-18-session-settings-drift-runtime-keys]]) rather than a one-off harvest choice, and
`setup.sh` parity shipped with the same fix carried over, plus `--harvest`/`--check` and the
`CC_TOOLKIT_HOME` anchor.

## Related
- [[../harness/memory-architecture]] — the settled, expanded map of the convention this session introduced
- [[2026-07-18-session-settings-drift-runtime-keys]] — closed the settings.json thread this session first raised
- [[2026-07-15-session-harvest-systematization]] — same-day prior session (v1.12.0 + v1.13.0), distinct topic
