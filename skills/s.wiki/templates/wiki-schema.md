# Wiki Schema

This file specializes the [wiki skill](../.claude/skills/wiki/SKILL.md) for **this particular wiki**. Edit freely — the skill reads this file on every activation, so changes take effect immediately.

The skill's default conventions (folder layout, page types, frontmatter, citation rules) live in `~/.claude/skills/wiki/SKILL.md`. Sections below override or extend those defaults for this domain.

---

## Purpose

<!-- One paragraph: what is this wiki for? What kinds of questions should it answer in 6 months? -->

## Source profile

<!-- Dominant source types and where they come from. -->
<!-- e.g. "Mostly academic papers (arxiv, JSTOR) and conference talks. Occasional blog posts." -->

## House style

<!-- How you want pages to read. -->
<!-- e.g. "Terse, neutral, third-person. Definitions before examples. Always include a quoted excerpt under each cited claim." -->

## Page types (extends defaults)

The skill ships with four built-in page types: `source`, `entity`, `concept`, `synthesis`. Add any domain-specific types below — each with a short description of what goes in it.

<!-- Examples:
- `paper` — academic papers, extends `source` with `abstract`, `methodology`, `findings`, `citations_made` sections
- `experiment` — for research wikis: hypothesis, method, result, follow-ups
- `character` — for book/story wikis: arc, relationships, scenes
- `meeting` — for team wikis: attendees, decisions, actions
-->

## Folder conventions (overrides defaults if non-empty)

Default folders: `raw/`, `sources/`, `entities/`, `concepts/`, `syntheses/`, `assets/`.

<!-- Add overrides or extras. e.g.
- Rename `entities/` → `people/` (this wiki is biography-heavy)
- Add `papers/` for academic sources alongside `sources/`
- Add `decisions/` for decision records
-->

## Domain glossary

Terms used in this wiki with non-standard or jargon meanings. Keeps the skill consistent across pages.

<!-- e.g.
- "S1" — single-month spread (industry term, not the camera)
- "compounding" — referring to knowledge accumulation, not interest
-->

## Recurring questions

Questions you find yourself asking the wiki often. Useful as a table of contents for `syntheses/`.

<!-- e.g.
- What are the main critiques of X framework?
- Who introduced concept Y, and what's the lineage?
- What experiments have I run on Z and what were the outcomes?
-->

## Notes to the skill

Anything else the skill should keep in mind when operating on this wiki — heuristics, exceptions, do-not-touch areas.

<!-- e.g.
- Do not edit pages in `archive/` — they are frozen historical snapshots.
- When a source mentions a person, always check `entities/` for an existing alias before creating a new page.
- Prefer extracting tables and figures into separate `assets/` markdown files rather than inlining.
-->
