---
type: concept
tags: [architecture, currency, conversion, display-lens, persistence, cache-safety]
origin: Propex Trading (PNL analytics engine, 2026)
sources: [project-internal]
updated: 2026-07-06
status: stable
---

# Convert-at-the-edge display lens

A pattern for presenting values in a user-selectable unit (currency, timezone,
denomination) **without** mutating internal state. Originated as a live MYR/USD PNL toggle;
applies to any "show the same numbers in a different unit" feature.

## Core principle — one base internally, convert once at the boundary

Keep the entire engine in a **single base unit internally** — every cache, register, and
calculation uses the native value. Perform the conversion at exactly **one place**: the
moment a snapshot is emitted to the UI. The selector is a **display lens**, not a state
change; it re-expresses the same base numbers on the way out the door.

## Why not swap the multiplier

It's tempting to convert by swapping each item's `point_value` / scale factor to a
base-equivalent. It's mathematically identical (`points × pv_base ≡ base_value × factor`)
but it invalidates every cache keyed on the base unit and risks writing converted numbers
into persisted stores. Converting once at the emission boundary keeps caches valid and
persisted state clean. This is the key architectural decision — **convert-at-edge vs
swap-the-multiplier, resolved on cache-safety.**

## Convert-each-then-sum

Mixed-unit aggregates must convert **each component first, then sum**. Summing native
numbers and converting the total once is incoherent when components have different native
units (e.g. a total spanning two currencies).

## Persistence guarantee

The conversion helper lives *only* in the emission path. Consolidation / settlement writers
never call it, so persisted history stays in the base unit regardless of the live toggle.
Frozen end-of-day snapshots pass an explicit `base_override = <base unit>` so they can never
be polluted by the live selection. History fields render with a "(base-unit)" tag and are
**not** reflowed by the toggle.

## Safety properties

- **Never fabricate** — a missing/zero rate returns no factor, and the caller falls back to
  the base-unit number. No garbage converted figure is ever shown.
- **Staleness gating** — rates older than a threshold flip an `ok` flag; the UI badge shows
  "(offline)" instead of silently using stale rates.

## Transfer note

Reach for this whenever a UI needs multiple views of the same underlying quantity. The
discipline — base-unit core, a single edge conversion, safe fallback, forced base on frozen
data — prevents the classic bug where a display preference silently corrupts stored history.

## Related

- [[concepts/fifo-vs-vwap-cost-basis]]
- [[concepts/cost-layer-as-derived-view]]

## Sources

- project-internal (distilled pattern; original lived in the origin project's wiki)
