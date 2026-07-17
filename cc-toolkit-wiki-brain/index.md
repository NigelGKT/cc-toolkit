# Global Brain — Index

The cross-project knowledge well. Deploys to every machine via `cc-toolkit`.
Last updated: 2026-07-17.

## Concepts

- [[concepts/fifo-vs-vwap-cost-basis]] — realized (FIFO) vs floating (VWAP) attribution, and unifying on FIFO-remainder
- [[concepts/convert-at-edge-display-lens]] — present values in a chosen unit without mutating state
- [[concepts/cost-layer-as-derived-view]] — layer commissions/fees as a derived view; never mutate gross
- [[concepts/declarative-intent-over-materialized-state]] — version declarative intent; rehydrate heavy/machine-specific state on deploy (npm lockfile pattern)

## Playbooks

- [[playbooks/cc-toolkit-deploy-lifecycle]] — the toolkit's own runbook: spin up → work → grow the brain → clean exit (with flowchart)

## Harness

Self-documentation of the Claude Code toolkit itself — see [[harness/README|harness/]] for the zone's charter.

- [[harness/harness-overview]] — anchor note: meta-map of the whole `~/.claude` tooling (with flowchart)
- [[harness/memory-architecture]] — the two memory systems (harness auto-memory vs. the three-tier project convention) and the routing rule between them
- [[harness/skills-catalog]] — `s.wiki`, `s.wrap-up`, `s.goal-run`, `s.ship-cc-tlkit`, and the `obsidian@obsidian-skills` plugin bundle: triggers + flows

## Incidents

How the toolkit has failed — open questions with evidence attached, **not** settled guidance. See [[incidents/README|incidents/]] for the zone's charter and lifecycle.

- 🔴 **open** — [[incidents/2026-07-16-self-description-drift]] — three self-description failures in one session (stale invariant / blind wiki probes / stale STATUS.md); nothing in the system could detect any of them. Root causes known; question 2 (Bootstrap self-guard) shipped for `s.wiki` in v1.18.0; question 5 answered at root in v1.19.0 (STATUS stopped storing what git owns, so it can no longer be false at rest); Layer 2, Q3 and Q7's breadth still open.

## Syntheses

- [[syntheses/2026-07-10-session-plugin-harvest]] — plugin harvest + hydrate for cc-toolkit (v1.8.0)
- [[syntheses/2026-07-15-session-harvest-systematization]] — file harvest (-Harvest) + direction-aware audit + drift-check hook + settings.json semantic compare (v1.12.0–v1.13.0)
- [[syntheses/2026-07-16-session-harness-zone-and-wiki-detection]] — dual charter + `harness/` zone, stale invariant amended, `/s.wiki` bootstrap footgun fixed (v1.15.0–v1.16.0)
- [[syntheses/2026-07-17-session-bootstrap-self-guard]] — `s.wiki` Bootstrap Step 0 safety gate: refuse to scaffold into a populated target (incident Q2, v1.18.0)
- [[syntheses/2026-07-17-session-single-pass-release-flow]] — `s.ship-cc-tlkit` single-pass release conductor; STATUS ledger removed + CHANGELOG frozen (retrieve-don't-duplicate); incident Q5 answered at root (v1.19.0)
