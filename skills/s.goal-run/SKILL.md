---
name: s.goal-run
description: Turn an existing, bounded piece of planned work (a backlog item, a refactor audit, a tiered plan) into a safely-executed autonomous run. Checks first whether the codebase has a live/running/deployed counterpart that constrains what's safe to test mid-run, then runs a one-round goal-setup interview (scope, isolation, commit cadence, verification style, guardrails, durable checkpoint), then executes item-by-item inside a /loop dynamic-mode run — locate, implement, verify, commit, checkpoint — until the goal is achieved. Never merges, pushes, or deletes files on its own. Assumes a plan already exists; if none does, says so instead of inventing scope. Use when the user wants to execute an existing plan/audit/backlog item autonomously, "run this until done", set up a /loop-driven refactor or migration, or explicitly invokes /s.goal-run.
---

# Goal Run

Turns a bounded, already-planned piece of engineering work into a self-paced autonomous execution run. One round of setup decisions, then it runs — via `/loop` dynamic mode — until the goal is achieved or it hits something outside its authorized scope.

**This skill assumes a plan already exists** — a backlog item, an audit, a tiered plan, a design doc. It does not invent scope from nothing. **Exactly one approval gate**: the goal-setup interview in Stage 1. Past that, it runs through without stopping to re-ask about anything already in scope. **Hard, permanent boundaries regardless of how the interview goes**: never merge, never push, never force anything, never delete files. Those are always separate, explicit asks — even after the goal is "achieved."

---

## On activation — orient (MANDATORY, silent)

Before presenting anything to the user:

1. **Identify the target plan.** Ask, or infer from the conversation, which backlog item / audit / plan document this goal executes. If genuinely nothing concrete exists yet, stop — see "If no plan exists yet" below. Don't scope work from scratch as part of this skill.
2. **Read the plan in full.** Note its age (created / last-updated date) against the current codebase. Line numbers, function names, and file references in an old plan drift as the codebase evolves — treat every reference in the plan as a hypothesis to re-verify, not a fact.
3. **Live-counterpart safety recon** (Stage 0, below) — do this before anything else touches a file. It determines what's safe to do for the rest of the run.
4. **Find the durable-checkpoint convention.** Look for an existing place in the project that already tracks this kind of progress — a wiki backlog page with a History/Resolution section, a CHANGELOG, a decisions log, a plan file with a status field. Prefer reusing one of these over inventing a new file. Only create a new file if nothing fits.
5. **Check what verification tooling actually exists.** A real test suite? Linters, type checkers, a build/compile step? If none of that exists, per-item verification in Stage 3 will need to be constructed ad hoc — note that now so Stage 1's verification question has real options to offer, not hypothetical ones.

---

## Stage 0 — Live-counterpart safety recon

Before scoping anything, determine whether this codebase has a live, running, or deployed counterpart that changes what's safe to do during execution. Try auto-detection first:

- Check for running processes tied to this codebase (OS process list; look for an interpreter/binary invocation referencing this project's files, or referencing a sibling/adjacent path that looks like the same project checked out elsewhere).
- Check whether the current working directory is a separate clone or worktree of the same repository as something deployed/running, and if so confirm they don't share a filesystem, process, or lock.
- Check for other signs of a live deployment: a running dev/prod server, a scheduled job, a service registration, a CI/CD pipeline that auto-deploys on push.

If auto-detection is inconclusive, **ask the user directly**: "Is there a live/running/deployed version of this I need to avoid disturbing?" Don't guess silently either way.

**If the answer is yes, treat it as a hard constraint for the rest of the run:**
- No launching, running, or deploying the code being changed during the loop itself — reserve that for one explicit, human-supervised step after the loop ends, not something the loop does autonomously.
- Verification during the loop must stay static/local (see Stage 1, verification dimension).
- State the relationship plainly in the goal spec (Stage 2) so it survives context compression across a long run — don't leave it as something only this conversation remembers.

---

## Stage 1 — Goal-setup interview (ONE round, via AskUserQuestion)

Present what orientation + Stage 0 turned up, then ask the following dimensions **in a single batch**, each with a recommended default informed by what was actually found — don't spread this across multiple turns:

1. **Scope** — how much of the plan to execute this run: all of it, a named subset, or a named risk tier if the plan already has one. If the plan has its own risk tiering (e.g. low/medium/high-risk buckets), surface it and recommend starting with the lowest tier rather than everything at once.
2. **Isolation** — where the work happens relative to any live counterpart and relative to the current branch: a dedicated branch, a dedicated worktree, or (if already working from a separate clone) nothing extra needed. Base the recommendation on Stage 0's findings, not a fixed default — sharing a working directory with something live pushes toward a worktree; already-separate pushes toward a plain branch.
3. **Commit cadence** — one commit per verified item (recommended: bisectable, easiest to pinpoint if something goes wrong over a long run), one commit at the end, or no auto-commits at all.
4. **Verification style** — what "verified" means per item, calibrated to what Stage 0/orientation actually found: a real test suite → run it; none → static checks plus targeted before/after equivalence tests, always baselined *before* editing so a later failure can be attributed correctly. If a live counterpart exists, explicitly exclude live launches from per-item verification and reserve one supervised end-to-end check for after the loop ends.
5. **Guardrails** — hard constraints pulled from the project's own docs (frozen contracts, forbidden operations, path conventions, deletion policies, anything the project has explicitly said not to touch). Quote them verbatim into the goal spec — don't paraphrase, and don't rely on remembering them from a docs file three files away once context starts compressing.
6. **Durable checkpoint** — where progress gets logged as the loop runs. Default to the existing convention found during orientation; only propose a new file if nothing fits.

**Do not proceed past this stage without the user's answers.** This is the skill's one approval gate. Once through it, don't stop to re-ask about anything already in scope — that defeats the point of an autonomous run.

---

## Stage 2 — Persist the goal spec

Before executing anything:

- Write the finalized spec — scope, guardrails (verbatim), process, the explicit "done" definition, and explicit non-goals ("never merge", "never push") — into the chosen durable-checkpoint location. This is what survives if conversation context gets compressed mid-run; don't leave it only in chat.
- Set up a TodoWrite list mirroring every item in scope, one entry per item plus a final verification/close-out entry.
- If the user wants a specific model or effort level for the execution itself (e.g. a higher-capability model via `/loop` dynamic mode), remind them to switch via `/model` before the loop starts — this skill runs under whatever model is already active; it doesn't control that itself.

---

## Stage 3 — Execution loop

For each item in scope, in order:

1. **Locate** — find the current code/location for real. If the plan is stale (per the orientation check), re-verify against current line numbers/names rather than trusting old references blindly.
2. **Implement** — the surgical change the item scopes, nothing beyond it.
3. **Verify** — per the Stage 1 verification style. Never skip this to save time, even on something that looks trivial.
4. **Commit** — stage specific files by name only, never `-A`/`.` (this is what protects the commit from sweeping in unrelated pre-existing dirty state that has nothing to do with the goal). Commit message identifies the item.
5. **Checkpoint** — append a line to the durable-checkpoint doc recording what landed and how it was verified, so progress is legible to the user (and to a future you) without replaying the whole conversation.

Drive this via `/loop` dynamic mode — self-paced, using `ScheduleWakeup` between iterations — until every in-scope item is done, or until something requires stepping outside the authorized scope. If that happens, stop and ask; don't improvise past what the goal spec actually authorized.

**Hard boundaries throughout, regardless of how the interview answers came out:**
- Never merge, never push, never force anything.
- Never delete files.
- Never take an action Stage 0 flagged as live-counterpart-risky, no matter how safe it seems in the moment.

---

## Stage 4 — Close-out

When every item is done:

- Run one final verification pass across **all** changed files together, not just per-item — a full compile/build/lint pass catches cross-item interactions that individual per-item checks can miss.
- Write a closing summary into the durable checkpoint: what landed, and what's explicitly still pending (a supervised live test, a merge decision, a push decision — whatever Stage 0/1 deferred to a manual step).
- Hand off to the project's own wrap-up flow (e.g. `/s.wrap-up`) for broader session bookkeeping — CLAUDE.md updates, commit-message drafting. This skill's job ends at "goal achieved and checkpointed"; don't duplicate wrap-up's stages here.
- State plainly, in the user's own language, exactly what still stands between "goal achieved" and "fully shipped." Never assume or take those remaining steps yourself.

---

## If no plan exists yet

This skill assumes a plan/backlog item already exists. If invoked with nothing concrete to execute, don't invent scope — say so plainly, and suggest a short planning pass first (Plan mode, a scoped audit, or just talking through what the goal should contain) before re-invoking this skill once something is actually written down.

---

## Tone and pacing

- One approval gate, not a menu at every stage.
- Once past the interview, run through — don't ask "should I continue?" between items.
- If the user interjects mid-run, pause, address it, then resume the loop rather than restarting it from scratch.
- Keep per-item reporting terse — a sentence per landed item is enough; save the detail for the close-out summary.
