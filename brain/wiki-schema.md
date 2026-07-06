# Wiki Schema — Global Brain

This file specializes the `s.wiki` skill for the **global brain** — the cross-project,
cross-client knowledge well that lives in `cc-toolkit` and deploys to every machine via
`setup.ps1` / `setup.sh` (lands at `~/.claude/brain/`). Edit freely; the skill reads this
on every activation.

Default conventions (folder layout, page types, frontmatter, citation rules) live in
`~/.claude/skills/s.wiki/SKILL.md`. Sections below override or extend those defaults.

---

## Purpose

Distilled, **transferable** knowledge — patterns, architectures, and client-agnostic
lessons that apply beyond the project they were learned in. This is the compounding well:
every project's wiki brain feeds its best concepts up here, scrubbed of specifics, so the
knowledge rides to every machine and every future engagement.

**This is the source of truth.** Curate it in the `cc-toolkit` repo clone, commit, push,
then redeploy. **Never edit the deployed `~/.claude/brain/` directly** — that's a deploy
target, like all other toolkit config.

## What belongs here / what does NOT

| Promote UP (belongs here) | Keep in the project wiki |
|---|---|
| A **pattern** true across clients (convert-at-edge lens, FIFO vs VWAP) | Session syntheses ("what I did on the 4th") |
| A **client-agnostic lesson / checklist** (→ `playbooks/`) | Raw client data (rate tables, account IDs, figures) |
| A reusable **architecture decision** rationale | Anything naming a client's people, brokers, files, line numbers |

The distil test: *strip every project-specific identifier and does a reusable idea remain?*
If yes, that idea is the concept. If nothing remains once scrubbed, it wasn't transferable —
leave it in the project.

## Provenance (`origin:` — required on every page)

Client identifiers are stripped from the **body**, but the source is recorded in frontmatter:

```yaml
origin: <project / client> (<context>, <year>)   # e.g. Propex Trading (PNL analytics engine, 2026)
```

`origin` is the only place a page names where the knowledge came from. The prose itself
stays client-agnostic so a concept reads as a general pattern.

> **Deferred:** these `origin:` values name real clients and the brain currently deploys
> everywhere. When client confidentiality across engagements becomes a live concern,
> revisit — options are an aliased codename + local-only key map, or a `-SkipBrain` deploy
> switch for client machines. Not addressed yet by choice.

## Page types

The dominant two:

### `concept` — a transferable pattern or idea
Folder: `concepts/`. Slug: kebab-case pattern name (`convert-at-edge-display-lens.md`).
Frontmatter: `type: concept`, `tags`, `origin`, `sources`, `updated`, `status`.
Body: definition → the mechanics/principle → why it matters → **Transfer note** (when to
reach for it elsewhere) → Related → Sources.

### `playbook` — a client-agnostic lesson or checklist (prose, not code)
Folder: `playbooks/`. Slug: kebab-case (`diagnosing-timezone-drift-in-pnl.md`).
Consulting patterns, gotchas, and repeatable checklists distilled from real engagements.
One lesson per file, scrubbed. Frontmatter: `type: playbook`, `tags`, `origin`, `updated`,
`status`.

The `source`, `entity`, and `synthesis` defaults remain available if ever needed, but the
brain is concept- and playbook-led.

## Graph view colour groups

Defined in `.obsidian/graph.json` → `colorGroups`. Applied top-to-bottom; first match wins.
Root files (`index`, `log`, `README`, `wiki-schema`) render in the theme default.

| Group | Query | Colour | Hex | Decimal rgb |
|---|---|---|---|---|
| Concept | `path:concepts/` | 🟢 | `#22c55e` | 2278750 |
| Playbook | `path:playbooks/` | 🟣 | `#8b5cf6` | 9133302 |
| Synthesis | `path:syntheses/` | 🟡 | `#f59e0b` | 16096779 |
| Source / Raw | `(path:sources/ OR path:raw/)` | ⚫ | `#6b7280` | 7041664 |

When adding new folders/page types, insert a group **above** the source/raw catch-all.

## House style

- **Pattern-first, terse, dense.** Lead with the transferable idea, not the project story.
- **No project internals in the body** — no client file names, line numbers, function names,
  people, or figures. If a mechanism needs illustrating, use generic pseudocode or field names.
- **Every concept ends with a `## Transfer note`** — one short paragraph on when to reuse it.
- **Code identifiers in backticks** only when generic (`point_value`, `net_position`).
- **Dates absolute.** **Status**: `draft` / `stable` / `stale` / `contested`.

## Flows (how the brain lives)

- **Promote (in)** — `s.wrap-up` Part C flags a generalizable concept/lesson at session end.
  You copy it from the project wiki into `brain/`, scrub it, set `origin:`, re-link, commit, push.
- **Query (out)** — before solving something cold, ask the brain: *"what does my brain say
  about X"* → `s.wiki` query against `~/.claude/brain/`.
- **Lint (maintain)** — periodic `s.wiki` health-check for contradictions, stale claims, orphans.

## Notes to the skill

- Curation happens in the **repo clone**, never the deployed copy.
- Do not paste large code blocks — describe the pattern; keep it language/framework-neutral.
- A concept that just restates one project's code adds nothing — capture the *why* and the
  *transfer*, or don't promote it.
