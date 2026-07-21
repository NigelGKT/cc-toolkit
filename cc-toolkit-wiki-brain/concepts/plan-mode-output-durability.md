---
type: concept
tags: [plan-mode, durability, wiki, memory]
origin: Propex Trading Analytics (I07 reconciliation replan, 2026)
sources: []
updated: 2026-07-21
status: stable
---

# Plan-Mode Output Isn't Durable — Freeze What Matters

A plan-mode session's output file is a **transient artifact**, not a durable record — if a
plan has value beyond the session that produced it, freeze a copy into the project's own
persistent memory before relying on it existing later.

## The principle

Plan-mode style workflows write their proposed plan to an auto-named, unversioned file outside
the project (e.g. under a tool's own local config directory). That file is convenient in the
moment but has none of the properties a durable record needs: it isn't version-controlled,
its name is often auto-slugged and unmemorable, and it can be silently lost across a machine
switch, a tool reset, or simply enough time passing. Treating it as "the plan, filed for later"
is a latent data-loss bug — it works until the one day someone goes looking for it and it's
gone.

The fix is a two-tier split:
1. **The transient file** — fine as a working surface during the session itself.
2. **A durable copy** — for any plan whose reasoning will matter again (a design later
   revisited, a decision whose rationale will be questioned), copy the substance into the
   project's own persistent memory (wiki, docs folder, changelog — whatever the project
   already uses) as a dated, version-controlled snapshot **before** the session ends.

The durable copy is historical record — frozen, not re-edited. A living page (backlog item,
design doc) can supersede its *framing* over time without needing to rewrite the frozen
snapshot; the snapshot stays as evidence of what was actually decided and when.

## Why it matters

- **Loss is silent and only discovered when it's expensive** — nobody notices a plan file is
  gone until they need it, by which point the reasoning behind a since-superseded decision is
  unrecoverable.
- **"I'll just re-derive it" isn't free** — reconstructing why a design took a particular shape
  from the current code alone is far more expensive than reading the original rationale.
- **A durable copy also survives the plan being revised.** When a plan gets replanned or
  re-scoped, the frozen original explains *why* the current version differs — without it, the
  history of a decision collapses to just its latest state.

## Transfer note

Reach for this at the end of any plan-mode (or equivalent design-then-approve) session where
the plan covers more than a trivial, one-off change. Before the session ends, copy the plan's
substance into the project's durable memory, dated, and link the living design page back to it.
Skip it for plans that are genuinely disposable — a plan whose only value is executing the very
next step doesn't need a historical record.

## Related
- None yet.

## Sources
- Derived from a project wiki incident: a 2026-05-26 plan-mode design file was already gone
  from disk by the time its replan needed it, ~16 tool-versions later — the replan session
  adopted the freeze-a-copy pattern going forward.
