# Global Brain — Index

The cross-project knowledge well. Deploys to every machine via `cc-toolkit`.
Last updated: 2026-07-15.

## Concepts

- [[concepts/fifo-vs-vwap-cost-basis]] — realized (FIFO) vs floating (VWAP) attribution, and unifying on FIFO-remainder
- [[concepts/convert-at-edge-display-lens]] — present values in a chosen unit without mutating state
- [[concepts/cost-layer-as-derived-view]] — layer commissions/fees as a derived view; never mutate gross
- [[concepts/declarative-intent-over-materialized-state]] — version declarative intent; rehydrate heavy/machine-specific state on deploy (npm lockfile pattern)

## Playbooks

- [[playbooks/cc-toolkit-deploy-lifecycle]] — the toolkit's own runbook: spin up → work → grow the brain → clean exit (with flowchart)

## Syntheses

- [[syntheses/2026-07-10-session-plugin-harvest]] — plugin harvest + hydrate for cc-toolkit (v1.8.0)
- [[syntheses/2026-07-15-session-harvest-systematization]] — file harvest (-Harvest) + direction-aware audit + drift-check hook + settings.json semantic compare (v1.12.0–v1.13.0)
