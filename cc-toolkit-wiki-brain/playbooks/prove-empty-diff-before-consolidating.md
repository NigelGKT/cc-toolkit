---
type: playbook
tags: [refactor, code-review, duplication, verification]
origin: Propex Trading (PNL analytics webapp, 2026)
updated: 2026-07-20
status: stable
---

# Prove the Diff Is Empty Before Consolidating Diverged Duplicates

Two near-twin functions whose guards have silently diverged tempt you to merge to the
"stricter" one. Don't merge until you've proven the *observable* behaviour is identical —
else a "cleanup" silently ships a behaviour change.

## The trap

A divergence in source ≠ a divergence on screen. The stricter-looking guard may be
unreachable or already masked:

- **Upstream** — the data contract can make the differing case impossible (e.g. a
  serializer that always emits a key as value-or-null, so `undefined` never arrives).
- **Downstream** — a shared formatter both twins call may already collapse the differing
  inputs to one output (e.g. both null and undefined → "—").

If either holds, the guards are equivalent for every input that can occur — the "bug" is
dead code and consolidation is provably a no-op.

## Checklist

1. Pin the exact input value(s) where the two guards diverge.
2. Trace upstream: can that value reach the function given the real producer contract?
3. Trace downstream: do shared helpers already normalize the divergent inputs?
4. If 2 or 3 makes it unobservable → safe pure de-dup; note the proof.
5. If it IS reachable + observable → real behaviour fork; decide correct behaviour
   deliberately, don't inherit whichever twin you kept.

## Payoff

Turns a vague "these look different, careful" into a decision backed by proof — you
either ship a clean de-dup with confidence, or you catch a genuine behaviour fork before
it reaches users.
