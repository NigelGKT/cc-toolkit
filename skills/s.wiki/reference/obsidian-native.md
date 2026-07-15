# Obsidian-Native Rendering — Bases · Canvas · Callouts · CLI · Defuddle

How this skill uses the **kepano/obsidian-skills** family (`obsidian-bases`, `json-canvas`,
`obsidian-markdown`, `obsidian-cli`, `defuddle`) to render the wiki natively in Obsidian.

## Division of labour

`s.wiki` owns the **knowledge architecture** — *what* pages exist, their frontmatter, links,
citations, provenance, and the log. The kepano skills own **Obsidian-native materialization** —
turning that structure into interactive, native artifacts. Don't reimplement their syntax here;
name the skill and let it own the details.

| Need | Skill | Artifact |
|---|---|---|
| Live views over frontmatter (dashboards, "all open backlog", "contested pages") | `obsidian-bases` | `.base` |
| Visual maps (architecture, decision lineage, dependency graphs) | `json-canvas` | `.canvas` |
| Callouts, embeds, block-refs, richer note bodies | `obsidian-markdown` | `.md` |
| Clean web→markdown for a URL source | `defuddle` | `raw/*.md` |
| Read/search/backlinks against a *running* vault | `obsidian-cli` | (queries) |

## Detecting capability

Read `<WIKI_ROOT>/.obsidian/core-plugins.json`:
- `"bases": true` → scaffold and maintain the Bases layer (native since Obsidian 1.9).
- `"canvas": true` → offer canvas maps.
- If `.obsidian/` is absent (folder never opened as a vault), skip auto-scaffolding Bases and
  mention that opening it as a vault unlocks the dashboard layer.

`obsidian-cli` needs both the `obsidian` binary on PATH **and** a running instance — check
`command -v obsidian` before ever using it; fall back to `grep`/`Glob` when absent (the common case).

---

## Bases — the dashboard layer (replaces Dataview)

Prefer **Bases over Dataview**: native (no community plugin), first-class files, interactive
tables/cards, and they read the exact frontmatter this skill already maintains. If you catch
yourself pasting a ```dataview``` block, make a `.base` instead.

**Standard dashboard set** — one `.base` per content folder plus a whole-vault health instrument,
all under `dashboards/`:
- `<folder>.base` per content type (e.g. `backlog.base`, `decisions.base`, `sources.base`) —
  global filter `file.inFolder("<folder>")`, a few views (grouped / filtered), computed columns.
- `health.base` — whole-vault lint instrument: *Contested* (`status == "contested"`), *Stale*
  (`status == "stale"`), *Orphans* (`file.backlinks.isEmpty()`), and **data-quality guards** that
  should read empty (enum drift on any tracked field). This auto-covers lint checks 1, 2, 3, 6.

**Scaffold on bootstrap** when `bases: true`, and whenever a new page type / folder is added.

**Syntax essentials** (full reference: the `obsidian-bases` skill):
- Filters: a single expression string, or an `and`/`or`/`not` object. Operators include `==`,
  `!=`, `<`, `>`, `&&`, `||`, `!`.
- Formulas: `if(cond, a, b)`, `date(s)`, `today()`, list `.isEmpty()` / `.length`.
- Views: `type` (table/cards/list/map), `name`, optional `groupBy {property, direction}`,
  `order` (column list), `summaries`.

**Gotchas (learned):**
- **Enum guards / name exclusions** — use a flat compound string, not a `not:` list (whose
  AND/OR semantics are ambiguous): `'priority != "URGENT" && priority != "HIGH" && …'`.
- **Orphans** — `'file.backlinks.isEmpty()'`; exclude roots with
  `'file.basename != "index" && file.basename != "log" && …'`.
- **Age columns** — subtracting dates yields a *Duration*; take `.days` before rounding:
  `'if(created, (today() - date(created)).days, "")'`. Never divide-then-round a Duration.
- **Null-guard formulas** with `if(prop, …, "")` — properties are missing on some notes.
- **Sorting** — don't emit an undocumented top-level `sort:` key; Bases tables are click-sortable,
  and `groupBy` handles grouping. Order columns so the sort target is visible.
- **Quoting** — wrap a formula containing `"` in single quotes: `'if(x, "Yes", "No")'`.
- Validate every `.base` as YAML before handing off (`npx --yes js-yaml <file>` when no PyYAML).

---

## Callouts & embeds (obsidian-markdown)

House-style for callouts — apply when a section's *type* is one of these, otherwise plain prose:

| Situation | Callout |
|---|---|
| Contested / contradiction section | `> [!warning]` |
| Incident, high/urgent severity | `> [!danger]` |
| Incident, normal severity / known bug | `> [!bug]` |
| Decision **Consequences**, neutral aside | `> [!note]` |
| Background / context | `> [!info]` |
| Recommendation / preferred path | `> [!tip]` |
| Verbatim source excerpt | `> [!quote]` |

Use **embeds** to avoid duplication: pull a decision's context into a backlog page with
`![[decisions/dec-NN-...#Context]]` rather than restating it. Use block-refs (`^id`) to cite a
specific claim across pages.

---

## Canvas maps (json-canvas)

Offer a `.canvas` when a page is inherently spatial and a linear note under-serves it:
- **Architecture / data-flow** syntheses — mirror the page's Mermaid diagram as canvas nodes/edges;
  use `file` nodes so boxes link to the underlying concept/synthesis pages.
- **Decision lineage** — `supersedes`/extends chains across `decisions/` as a node graph.
- **Dependency graphs** — backlog items with `depends-on` relationships.

Keep the source-of-truth in markdown; the canvas is a *view*. Validate JSON (unique 16-hex node
IDs; every edge `fromNode`/`toNode` resolves) before handing off.

---

## Web ingest (defuddle)

When an ingest source is a **URL**, use the `defuddle` skill to extract clean markdown into `raw/`
(strips nav/clutter, saves tokens) instead of `WebFetch`. Then run the normal ingest workflow on
the saved `raw/` file. Non-URL sources (files, pasted text, "this conversation") are unaffected.

---

## Obsidian CLI (optional, gated)

Only when `command -v obsidian` succeeds **and** a vault is open:
- Lint orphan/backlink accuracy: `obsidian backlinks file="…"`, `obsidian search query="…"`.
- Quick reads without loading files: `obsidian read file="…"`.

Never assume availability. The skill's default path is grep/Glob over the flat file tree; the CLI
is a precision upgrade for interactive sessions, not a dependency.

---

## Workflow hooks (where each plugs in)

- **Bootstrap** — after scaffolding folders, if `bases: true`: create `dashboards/` + the standard
  `.base` set, and add a `path:dashboards/` graph colour group.
- **Ingest** — URL source → `defuddle` into `raw/`. Bodies use the callout house-style above.
- **Query** — structured lookups ("all open HIGH backlog") → point at / build a Base; open-ended
  questions → prose synthesis as before.
- **Lint** — read `health.base`'s views first (Contested / Stale / Orphans / guards); fall back to
  grep for checks Bases can't express (missing-page / dangling-link, log gaps, topic gaps).
