# Incidents — How the Toolkit Has Failed

Focused analyses of failures in `~/.claude` / `cc-toolkit` itself: what happened, root cause,
what it reveals, and the design questions left open. Part of the self-documentation charter
alongside [[../harness/README|harness/]] — see [[../wiki-schema]].

Part of the [[../wiki-schema|global brain]] — coloured 🔴 in the graph view.

## Why this is its own zone

An incident is **not** a harness note and **not** a playbook:

- `harness/` describes **how the system works** — stable, descriptive, true at rest.
- `playbooks/` are **settled procedures** — the answer, already decided.
- `incidents/` are **open questions with evidence attached** — temporal, unresolved, and
  actively *not* something to follow.

Mixing them is the failure this zone exists to avoid: an open incident sitting among settled
documentation reads as settled. The separation is what keeps `status: open` meaningful.

## Lifecycle

`status: open` → `analyzed` → `resolved`. An incident's own vocabulary, overriding the
brain-wide `draft`/`stable`/`stale`/`contested` (which describes *reliability*, not *lifecycle*).
On `resolved`, say **where** the response shipped — version, commit, or the page that now
carries the rule.

## What belongs here

- A failure worth understanding rather than just fixing — especially one that recurred, or that
  a fix wouldn't prevent from recurring in a new form.
- A cluster of failures that share a root cause, captured together (the pattern is usually the
  finding, not any single instance).
- Near-misses. A bug that was armed but never fired still teaches.

## What does NOT belong here

- A settled rule or checklist → `../playbooks/`.
- A description of how something works → `../harness/`.
- A chronological record of a work session → `../syntheses/`. An incident may *cite* a session
  note, but it is an analysis, not a log.
- A transferable pattern scrubbed of this toolkit → `../concepts/`.

## House rule

**State findings; don't prescribe.** The design response is decided when the incident is
revisited — writing the fix into the capture pre-empts the thinking the capture exists to enable.
Record what is *known*, what is *suspected*, and what is *open*, and keep those three apart.
