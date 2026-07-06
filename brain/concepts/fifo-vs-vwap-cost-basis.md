---
type: concept
tags: [pnl, cost-basis, fifo, vwap, trading-analytics]
origin: Propex Trading (PNL analytics engine, 2026)
sources: [project-internal]
updated: 2026-07-06
status: stable
---

# FIFO vs VWAP cost basis

A recurring design fork in trade-PNL engines: **realized** PNL and **floating**
(unrealized) PNL can be computed on different cost-basis methods, and mixing them creates
attribution inconsistencies.

## FIFO realized

Match buys against sells in first-in-first-out order, per `(trader, product)` group. For
each group:

- `realized_volume = min(total_buy_volume, total_sell_volume)` — the round-tripped lot count
- `buy_vwap`, `sell_vwap` — volume-weighted average prices of the *matched* lots
- `realized_pnl = (sell_vwap − buy_vwap) × realized_volume × point_value`

## Position-aware VWAP (a common floating method)

The unrealized portion walks newest trades backward through order history until the net
position size is reached, takes the volume-weighted average price of those rows, then floats:

```
float_pnl = (current_price − position_vwap) × net_position × point_value
```

## FIFO-remainder (the alternative that unifies them)

After FIFO matching consumes `realized_volume` lots, use the *unmatched leftover rows* as
the cost basis for the open position. Both realized and floating PNL then derive from the
same FIFO ordering of trades — one consistent view.

## Why the asymmetry matters

When realized and floating use different methods, the same `(trader, product, set of trades)`
can produce inconsistent attribution. A trader's reported floating PNL may not match what
they'd realize by closing the position at the current price, because VWAP and FIFO disagree
on which lots are "open" vs "closed". The mismatch is most visible when a trader mixes
buy/sell trades at varying prices intraday.

## Transfer note

Any engine reporting both realized and floating PNL should choose this consciously.
Unifying on FIFO-remainder removes the inconsistency at the cost of more bookkeeping;
VWAP-floating is simpler but will diverge from realized attribution. Decide up front — a
later switch invalidates every historical floating number.

## Related

- [[concepts/cost-layer-as-derived-view]] — commissions/fees layered on top of gross PNL
- [[concepts/convert-at-edge-display-lens]] — presenting the same PNL in a chosen currency

## Sources

- project-internal (distilled pattern; original lived in the origin project's wiki)
