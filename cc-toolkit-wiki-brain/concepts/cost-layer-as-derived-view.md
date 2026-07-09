---
type: concept
tags: [architecture, cost-modelling, commission, derived-view, ledger, immutability]
origin: Propex Trading (PNL analytics engine, 2026)
sources: [project-internal]
updated: 2026-07-06
status: stable
---

# Cost layer as a derived view

How to add a cost layer (commissions, fees, taxes, slippage) to a PNL system **without**
corrupting the gross figures it sits on top of. Originated with an exchange/broker
commission model.

## Principle — never mutate gross; derive net

Gross PNL is authoritative and immutable. The cost layer is computed as a **derived view**:
`net = gross − cost`. Gross is never overwritten, so removing or re-rating the cost layer is
always reversible and auditable. A cost model that edits gross in place destroys the ability
to reconcile back to the raw trades.

## Per-side vs round-trip (the counting trap)

Charge rates are usually quoted **per side** (per contract leg). A round-trip (one buy + one
sell) is **2 sides**. If your volume/lot field already counts sides, then
`cost = sides × rate_per_side` is automatically round-trip-correct. Get this wrong and every
cost is off by a factor of 2. **State explicitly** whether the lot field counts sides or
round-trips — this is the single most common source of error in cost modelling.

## Storage & editability

Keep the rate table in **config, not code** — editable by operators via the UI, with only
the resolved `total` read by the engine. Products with no configured rate resolve to a zero
contribution rather than erroring, so partial coverage degrades gracefully.

## Freeze into history

Compute the per-period cost at consolidation and **freeze it into the stored record**,
back-filling on read so every historical row carries its own cost figure. Net-of-cost stays
reproducible even if rates change later — you never retro-apply today's rates to old periods.

## Display

Show "after-cost" only where it's meaningful — per-period series for books with non-zero
cost in that window. Leave cumulative / gross series unadorned. No-activity periods →
after-cost equals gross.

## Transfer note

Any system layering fees, taxes, or commissions on a core figure should keep the core
immutable and treat the layer as a lens. Persist the computed cost per period so history is
reproducible. And nail the per-side/round-trip counting rule before anything else — it's the
error that silently doubles or halves every cost figure.

## Related

- [[concepts/fifo-vs-vwap-cost-basis]]
- [[concepts/convert-at-edge-display-lens]]

## Sources

- project-internal (distilled pattern; original lived in the origin project's wiki)
