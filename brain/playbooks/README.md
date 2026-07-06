# Playbooks — Cross-Project Lessons

Generalizable, **client-agnostic** knowledge that isn't a structured concept: consulting
patterns, gotchas, and repeatable checklists distilled from real project work. Prose, not
code.

Part of the [[../wiki-schema|global brain]] — coloured 🟣 in the graph view.

## What belongs here

- Reusable lessons that apply across clients/projects
  (e.g. "PNL data with timezone drift → checklist to diagnose").
- Patterns worth repeating on the next engagement.

## What does NOT belong here

- Client names, credentials, proprietary data, or project-specific detail — that stays in
  the project's own repo + wiki. Record the source in `origin:` frontmatter instead.
- Anything that is really a structured **concept** (→ `../concepts/`), a **command**, or a
  **skill** (→ `cc-toolkit/commands/`, `cc-toolkit/skills/`).

## How it fills up

The `s.wrap-up` ritual flags promote candidates at the end of each project session
(Part C). Client-agnostic lessons land here as short notes.

One lesson per file, kebab-case filename. Frontmatter: `type: playbook`, `tags`, `origin`,
`updated`, `status`. Keep entries short and scrubbed.
