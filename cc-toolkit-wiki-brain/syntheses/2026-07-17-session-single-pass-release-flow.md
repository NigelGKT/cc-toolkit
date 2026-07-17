---
type: synthesis
tags: [session-note]
sources: []
updated: 2026-07-17
status: stable
query: "Session note — single-pass release flow (s.ship-cc-tlkit) + retrieve-don't-duplicate"
---

# Session Note — 2026-07-17 — Single-Pass Release Flow + Retrieve-Don't-Duplicate

## What was attempted

Collapse the scattered cc-toolkit round-trip (edit in `~/.claude` → harvest → wrap-up → commit/push
→ deploy down) into one conductor skill — and fix the data duplication that made the close-out
ritual's own output false at rest.

## What shipped

- **`skills/s.ship-cc-tlkit/`** — new single-pass release conductor: guard → harvest up → author docs
  in the repo → **one** consolidated gate (files staged by name + commit message + explicit
  push/deploy intent) → commit + push → deploy down. Replaces the six-step prose close-out runbook.
  The old **two-harvest** dance collapses to one because the docs are authored in the repo, not
  `~/.claude`.
- **Root-cause fix for the STATUS drift.** The recurrence was never "step 6 was forgotten" — it was
  that `STATUS.md` stored commit/SHA state **git already owns**, which cannot be true until *after*
  the commit containing it. Removing the data (STATUS → state + intent only) deletes the failure
  class; step 6 no longer exists. Answers [[../incidents/2026-07-16-self-description-drift]]
  question 5 more strongly than reordering the ritual would.
- **`CHANGELOG.md` frozen to a signpost** — it was a *third* copy of a record git + `syntheses/`
  already hold. Retained as an archive through v1.18.0; not deleted.
- **`CLAUDE.md`** — encoded the governing rule: **retrieve, don't duplicate** (git = history; wiki =
  synthesis; web = cache the *distilled answer + source URL*, never a bare pointer, because a URL
  can rot where a local repo cannot).
- **`setup.ps1`** — persists `CC_TOOLKIT_HOME` at User scope on every deploy, so a fresh machine has
  an anchor without anyone setting it by hand.
- **Anchor-resolution fix** (`drift-check.ps1` + the skill's Step 0 guard) — resolve from the
  **persisted scope**, not the process env. A session inherits its environment at launch, so
  `$env:CC_TOOLKIT_HOME` is empty in any session started without it: *that* is why the hook fired in
  some sessions and silently no-op'd in others.
- Docs synced: deploy-lifecycle runbook + flowchart, [[../harness/skills-catalog]] entry, incident
  Q5 (answered) / Q7 (partial) responses.

## What was deferred

- `setup.sh` (Unix) parity for `-Harvest` / `-Check` / the anchor.
- Root-fixing the harvest scan (exclude `settings.json` + gitignored paths). The skill defends by
  staging **by name** instead, so the noise cannot reach a commit either way.

## Open threads

- **Diagnostic lesson — Layer 2, again.** *"The drift-check hook is silently dead"* was asserted from
  a **single probe of the process env** inside a long-running session, while `.toolkit-drift-check`
  (dated 2026-07-15, written only on a *successful* `-Check`) was already in context and disproved
  it. The correction then over-swung to "the hook was fine." Both were wrong: the accurate finding —
  **env-inheritance-dependent**, dead in *that* session, alive in others — surfaced only by comparing
  process env against the persisted scopes. Same *probe-over-evidence* pattern the incident records,
  and the disproof was in hand the whole time.
- **`s.ship-cc-tlkit` Step 1 assumes work is authored in `~/.claude`.** When a session authors
  directly in the repo (as this one did), harvest is a correct **no-op** — the skill should say so
  rather than imply `-Harvest -Force` is unconditional.
- **`settings.json` still uncommitted.** Read, not assumed: a full key reorder + the two
  plugin-hydration runtime keys (`extraKnownMarketplaces`, `enabledPlugins`) + exactly one real
  change, `effortLevel` `high`→`xhigh`. Decide separately.

## Related
- [[../playbooks/cc-toolkit-deploy-lifecycle]] — the close-out runbook this session rewrote
- [[../harness/skills-catalog]] — where `s.ship-cc-tlkit` is catalogued
- [[../incidents/2026-07-16-self-description-drift]] — the drift this session root-caused
