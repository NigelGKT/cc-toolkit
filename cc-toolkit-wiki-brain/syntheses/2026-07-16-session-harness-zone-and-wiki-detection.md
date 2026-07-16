---
type: synthesis
tags: [session-note]
sources: []
updated: 2026-07-16
status: stable
query: "Session note — harness zone + dual charter + wiki detection fix (v1.15.0 + v1.16.0)"
---

# Session Note — 2026-07-16 — Harness Zone + Wiki Detection

## What was attempted

Give the global brain a home for **self-documentation of the Claude Code toolkit itself**
(memory routing, deploy/harvest mechanics, skills) rather than leaving it tacit or squatting in
the transferable-patterns space. Investigation found the infrastructure already existed — all
three memory tiers, the brain, and its deploy path — so the work reduced to content plus a
schema amendment, not a build.

## What shipped

- **Dual charter (v1.15.0)** — `wiki-schema.md` now declares two charters: transferable patterns
  (`concepts/`, `playbooks/`) + harness self-doc (`harness/`). Registered the `harness` page type
  and two house-style carve-outs: harness pages *may* name toolkit internals (their subject *is*
  the toolkit), and `## Transfer note` is optional for self-doc rather than mandatory.
- **`harness/` zone (v1.15.0)** — 4 notes: [[harness/harness-overview]] (anchor meta-map with
  flowchart), [[harness/memory-architecture]] (the two memory systems — harness auto-memory vs.
  the three-tier convention — and the routing rule between them), [[harness/skills-catalog]],
  [[harness/README]]. Graph colour group added for `path:harness/`.
- **Deploy playbook extended (v1.15.0)** — [[playbooks/cc-toolkit-deploy-lifecycle]] predated the
  `-Harvest` feature (v1.12–v1.13), so it lacked the general file-harvest runbook and the
  drift-check-hook mechanics. Both added, plus a session close-out runbook.
- **Stale invariant amended (v1.15.0)** — "never edit the deployed copy" (written before
  `-Harvest` existed) → "prefer the repo clone; local editing is supported via `-Harvest` —
  harvest promptly, since the next `-Force` deploy destroys an unharvested edit and the
  drift-check hook is the only guard." Fixed in `wiki-schema.md` (2 places) + the playbook.
- **Wiki detection fix (v1.16.0)** — `/s.wiki` from the cc-toolkit root would **bootstrap a fresh
  vault over the repo**: both probes miss a subfolder brain, and cc-toolkit's `CLAUDE.md` *is* the
  global contract, so it carried no `## Wiki` pointer. Fixed both ways: a scope-gated `## Wiki`
  section in the global contract (the relative path `./cc-toolkit-wiki-brain/` is identical from
  both its homes), plus a subfolder-glob fallback in `s.wiki` and `s.wrap-up` probes.

## What was deferred

- **Harness pass 2** — session lifecycle & harness surface: plan mode, Explore/Plan subagents,
  one-task-per-session → checkpoint → `/clear`, hook mechanics in depth, `settings.json`
  permission model, statusline.
- **`setup.sh` parity** for `-Harvest`/`-Check` (Windows-primary; Unix deferred).

## Open threads

- **`settings.json` `effortLevel`** — local `xhigh` vs repo `high`, still undecided. Harvest
  sweeps it up mechanically (no per-file filter), so it must be excluded at staging time each
  session until settled.
- **v1.14.0 has no session note** — syntheses jump 07-10 → 07-15, and the 07-15 note covers
  v1.12/v1.13 only. Same failure mode this session nearly repeated: Stage 0 was initially skipped
  on a false "no wiki" verdict, despite two prior session notes sitting in this very folder.
  The detection fix above is the structural remedy.
- **`~/.claude/playbooks/`** is legacy — README only, not on the deploy manifest. Dead weight.
- **Harvest doesn't respect `.gitignore`** — it enumerates the filesystem, so gitignored runtime
  state participates in drift detection. Surfaced this session as `.obsidian/workspace.json`
  appearing as a harvest candidate despite being unversionable (`.gitignore` already does the
  right thing: `**/.obsidian/*` with `!**/.obsidian/graph.json`). Benign here — it landed on the
  `RepoNewer` side — but on the `LocalNewer` side it would trigger the drift-check hook's
  "not yet harvested" nag over a file that can never be committed. Same alarm-fatigue class as
  the `settings.json` false-positive fixed in v1.13.0; the fix would be symmetric (exclude
  gitignored paths from the drift scan). Also note `graph.json` itself mixes declarative config
  (`colorGroups`, worth versioning) with runtime view state (`scale`, `close`, `collapse-*`,
  which Obsidian rewrites constantly) — see [[../concepts/declarative-intent-over-materialized-state]].
