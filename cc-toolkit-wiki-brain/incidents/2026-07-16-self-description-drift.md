---
type: incident
tags: [self-description, documentation-decay, detection-gap, agent-behaviour, bootstrap]
origin: GKT cc-toolkit (harness zone session, 2026-07-16)
updated: 2026-07-17
status: open
---

# Self-Description Drift — Three Failures in One Session

**Status: open.** Root causes are known; the design response is not decided. Captured for
deliberate revisit — see [[#Open design questions]]. Session record:
[[../syntheses/2026-07-16-session-harness-zone-and-wiki-detection]].

## One-line statement

The toolkit's account of itself was false in three separate places, all silently, and **nothing
in the system could have told us** — every one was caught by a human noticing a contradiction.

---

## What happened

A session to *add* self-documentation (the `harness/` zone, v1.15.0) instead kept tripping over
places where existing self-documentation was already wrong.

### Failure 1 — Stale invariant (staleness)

`wiki-schema.md` (×2) and the deploy playbook stated, under **"Key invariants (don't violate)"**:
*"Never edit the deployed `~/.claude/cc-toolkit-wiki-brain/` — curate in the repo clone."*

Correct when written (2026-07-10). Invalidated 2026-07-15 by v1.12.0–v1.13.0, which added
`-Harvest` and made local→up a first-class supported direction. Never revisited.

**Subtlety that mattered:** it didn't become *wrong*, it became *over-strict*. The real risk it
guarded (an unharvested edit is destroyed by the next `-Force` deploy) was still real — only the
absolute prohibition was obsolete. Over-strict rules are harder to notice than false ones,
because following them still works.

**How it surfaced:** only because the operator chose a cadence that violated it and the reason
was checked. Nothing flagged it.

### Failure 2 — Blind wiki probes (migration gap, *not* staleness)

`/s.wiki` invoked from the cc-toolkit repo root resolves the wiki root two ways, then gives up:
probe `./wiki-schema.md` at CWD (miss — the brain is a subfolder), or scan CWD's `CLAUDE.md` for
a `## Wiki` pointer (miss — cc-toolkit's `CLAUDE.md` **is** the global contract, so no project
pointer was ever put in it). Verdict: "no wiki exists" → **Bootstrap** → scaffolds `index.md`,
`log.md`, `sources/`, `entities/` **over the repo root**.

**This was armed and live, not theoretical.** It had never fired only because nobody had run
`/s.wiki` from that directory.

**Distinct from Failure 1:** nothing went stale here. The `## Wiki` pointer mechanism was
introduced later (by `s.wiki` bootstrap Step 2b, for *new* projects) and the pre-existing brain —
a subfolder since the v1.5.0 `brain/` → `cc-toolkit-wiki-brain/` rename — was never backfilled.
A **migration gap**: the new mechanism shipped, the existing instance was left behind.

**The two probes weren't redundant.** They were blind to the *same* layout, so having two bought
nothing.

### Failure 3 — Stale STATUS.md (structural, *never* true at rest)

`STATUS.md` claimed the v1.15.0/v1.16.0 work was *"not yet committed"* after all three commits
were pushed. Identically, the pre-existing v1.14.0 entry claimed uncommitted work that was
already on `origin/main`.

**Not carelessness — ordering.** The session close-out ritual writes `STATUS.md` at step 3
(wrap-up), but the commit doesn't exist until step 5. `STATUS.md` is therefore **stale by design
at the moment of push**. The ritual had no step that could make it true. It failed twice for the
same reason, and would have failed every time.

Worse: `STATUS.md` is the *designated re-anchor point* for the next session — so its failure mode
is to actively mislead, sending the reader to redo shipped work.

**Third recurrence — after the fix, while closing out this incident.** The response to Failure 3
(close-out **step 6**: refresh `STATUS.md` *after* push) was written and shipped in `b113d8b`.
Then `v1.17.0` (`ec8fb35`, this very incident's zone) was committed **without** its CHANGELOG
entry and **without** the step-6 STATUS refresh — the identical drift, a third time, in the same
session, immediately after the fix. The next-session prompt "lets continue where we left off"
landed on a half-closed version. **This is the sharpest evidence in the whole incident:** step 6
is *prose an agent must remember to execute*, not an enforced gate, so it did not fire. It
directly answers open questions 5 and 7 below — a fix that lives only as a written instruction
inherits the exact failure mode it was meant to cure. Any response that ends at "document the
step" is choosing the option this line just falsified.

---

## Layer 2 — Agent behaviour (independent of the bugs above)

The tooling bugs are real. They are **not** a sufficient explanation. In each case the assistant
held information that contradicted the procedural output and did not act on the contradiction:

- **Declared "no wiki detected"** while having spent the entire session editing that wiki, with
  **two prior session notes** sitting in the very folder being denied. A mechanical probe result
  was reported as fact over direct contextual knowledge. The operator had to push back
  ("could you check again?") to surface it.
- **Consequence:** Stage 0 was skipped and the session note was silently lost — the same failure
  that left v1.14.0 without one. The bug caused it; the failure to question it *let* it happen.
- **Edited the repo copy instead of the deployed copy**, contradicting the cadence agreed minutes
  earlier. Self-caught and reverted cleanly; no damage.
- **Wrote `STATUS.md`, then immediately invalidated it by committing** — and didn't notice until
  asked "is status md updated to reanchor?".

**Pattern: deferred to procedure over evidence.** Three of three were caught by the operator, not
the assistant. Any design response that assumes the agent will notice is building on the thing
that just failed.

---

## What this reveals

**The toolkit has no feedback loop on its own self-description.** It has drift detection for
**files** — `setup.ps1 -Check`, content-hash authoritative, wired to a `SessionStart` hook. It has
**nothing** for semantic drift between what its documents *claim* and what its code *does*. That
class of divergence is invisible by construction: docs have no tests, and prose can't fail a hash.

**The three failures are not one class** (worth resisting the tidy story):

| # | Class | Was it ever true? | Fix shape |
|---|---|---|---|
| 1 | Staleness | Yes — invalidated later | Revisit on change |
| 2 | Migration gap | No — never true for this instance | Backfill on mechanism change |
| 3 | Structural | No — never true at rest | Reorder the ritual |

What unites them is **not** the cause. It's that all three fail **silently**, and the only
detector in the system is a human noticing a contradiction.

**Uncomfortable tension:** this session's headline deliverable (`harness/`, v1.15.0) is *more
documentation*, premised on writing the process down being useful. All three failures **were**
documentation. More docs is not obviously the remedy — unmaintained docs mislead worse than no
docs, because they're trusted. Whether the `harness/` zone becomes an asset or three more
liabilities depends entirely on whether anything maintains it. Nothing currently does.

**Hypothesis worth testing (not yet a conclusion):** the invariant that went stale stated a
**rule without its why** — *"never edit the deployed copy"* rather than *"…because the next
`-Force` deploy overwrites it."* With the *why* attached, a reader can evaluate whether it still
applies; without it, the rule is opaque and survives past its own justification. The v1.15.0/v1.16.0
notes were deliberately written to carry the *why*. **That's an untested bet, not a proven
practice** — and this incident is partly its rationale, so it should not be cited as evidence for
itself.

---

## Open design questions

For the revisit. Deliberately **not** answered here.

1. **Can semantic self-description drift be *detected*, or only *prevented*?** Is there any
   cheap check ("does this doc still describe the code?") or is the only lever making docs
   age well by construction?
2. **Should destructive operations self-guard, independent of upstream correctness?** Bootstrap
   will scaffold into a populated directory. A *"refuse to scaffold into a non-empty folder /
   repo root without explicit confirmation"* check would have made Failure 2 **harmless
   regardless of whether the probe was right**. Guards that don't depend on the correctness of
   the thing they guard are the only ones that survive an incorrect probe. **Shipped for `s.wiki`
   in v1.18.0** — Bootstrap's new Step 0 safety gate; see *Responses shipped so far*. The analogous
   guard does **not** apply to `s.wrap-up`: its wrong-probe failure is *omission* (it silently skips
   the session note), not *destruction*, so there is no write to guard — that side needs a
   visibility fix and stays open.
3. **Does adding documentation reduce or increase this risk?** See the tension above. What is
   the maintenance obligation a new doc incurs, and who discharges it?
4. **Does "state the why, not just the rule" actually make docs age better?** Testable
   prediction: rules-with-why should survive system changes that invalidate bare rules.
5. **Should rituals be ordered so their artifacts are true at rest?** Failure 3's fix (close-out
   step 6) is a patch on one ritual. Is there a general principle — *"no ritual may leave its own
   output false"* — and what else violates it?
6. **When a mechanism is added, what backfills existing instances?** Failure 2's root cause. The
   `## Wiki` pointer shipped for new projects; nothing swept the old one.
7. **How is a fix confirmed, given skills are prose, not code?** The v1.16.0 probe fix was
   verified *by simulating the probe steps in a shell* — not by running `/s.wiki` end-to-end from
   the cc-toolkit root, which remains **untested**. Prose guardrails have no test suite; a
   careless read still skips the new step (c).

## Responses shipped so far (partial — do not mistake for resolution)

- **v1.15.0** — invariant amended in all three locations, with the *why* attached.
- **v1.16.0** — scope-gated `## Wiki` pointer + one-level `*/wiki-schema.md` glob fallback in
  both probes. **Layer 1 only** — a careless read still skips the fallback, and Bootstrap remains
  unguarded (question 2).
- **`chore` (b113d8b)** — close-out runbook step 6: refresh `STATUS.md` *after* push. **Proven
  insufficient the same session** — v1.17.0 was committed skipping it (see Failure 3, third
  recurrence). It fixes the *ordering* but not the *enforcement*; a step only an agent remembers
  is not a guard (question 5, question 7).
- **v1.17.0 closeout `chore`** — belated CHANGELOG entry + step-6 STATUS refresh for `ec8fb35`,
  plus this evidence. Completes the paperwork; does **not** prevent the next recurrence.
- **v1.18.0** — **question 2 shipped for `s.wiki`.** Bootstrap gains a mandatory **Step 0 safety
  gate**: it inspects the final `WIKI_ROOT` on disk and refuses to scaffold into a non-empty target
  (repo root / project root / any pre-existing files) without explicit confirmation. This is the
  first response here that does **not** depend on the probe being right — a wrong probe is downgraded
  from data-loss to a question. Verified by scratch-fixture simulation; a true end-to-end run is
  deferred (needs a skill reload — question 7). `s.wrap-up` intentionally untouched: its mirror
  failure is silent omission, which needs a visibility fix, not a write-guard.
- **Still unaddressed:** Layer 2, question 3, and the enforcement gap the third recurrence exposed;
  question 2 remains open for `s.wrap-up`. That is why this stays `open`.

## Related
- [[../syntheses/2026-07-16-session-harness-zone-and-wiki-detection]] — the session record
- [[../playbooks/cc-toolkit-deploy-lifecycle]] — close-out runbook (step 6), amended invariant
- [[../harness/skills-catalog]] — the probe behaviour of `s.wiki` / `s.wrap-up`
- [[../harness/harness-overview]] — the tooling map these failures sit in
- [[../concepts/declarative-intent-over-materialized-state]] — adjacent: `.obsidian/` mixes
  declarative config with runtime state, and harvest enumerates the filesystem rather than git,
  so gitignored UI state joins the drift scan (open thread, same alarm-fatigue class as the
  `settings.json` false-positive fixed in v1.13.0)
