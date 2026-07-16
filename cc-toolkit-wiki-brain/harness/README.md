# Harness — Self-Documentation of the Claude Code Toolkit

Process maps and catalogs for `~/.claude` / `cc-toolkit` **itself** — not a transferable
pattern, the operating manual for this specific setup. Prose and diagrams, may name toolkit
files/scripts/skills directly (a carve-out from the brain's default house style — see
[[../wiki-schema]]).

Part of the [[../wiki-schema|global brain]] — coloured 🔵 in the graph view.

## What belongs here

- How the memory/knowledge tiers route facts (contract vs. working state vs. long-term brain).
- The deploy/harvest lifecycle mechanics (beyond the day-to-day runbook already in
  [[../playbooks/cc-toolkit-deploy-lifecycle]] — this is architecture, that is the runbook).
- The skills catalog: what each global skill does and what triggers it.
- Session-lifecycle and harness-surface notes (hooks, settings, subagents) — pass 2, not yet written.

## What does NOT belong here

- A **transferable pattern** usable outside this toolkit → `../concepts/`.
- A **client-agnostic consulting lesson** → `../playbooks/`.
- Anything naming a client, project, or engagement detail — this zone is 100% about the
  toolkit and carries no client data at all.

## How it fills up

Written directly during a deliberate mapping session (not `s.wrap-up`'s automatic promote
flow — harness notes are architecture documents, not session-derived lessons). One process
per file, kebab-case filename. Frontmatter: `type: harness`, `tags`, `origin`, `updated`,
`status`.
