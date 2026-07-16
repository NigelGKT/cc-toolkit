---
name: s.wiki
description: Build and maintain a persistent Obsidian-compatible knowledge wiki in the current folder. Use when the user wants to scaffold a new wiki, ingest sources (articles, papers, transcripts, notes) into one that exists, query against it, or lint it for contradictions, orphans, and stale claims. Triggers on phrases like "set up a wiki", "ingest this into my wiki/notes/brain/knowledge base", "what does the wiki say about X", "add this source", "health-check the wiki", or explicit /s.wiki invocation in any project folder. Produces interlinked markdown with YAML frontmatter, inline [[wikilinks]] citations, and grep-parseable logs.
---

# Wiki

A skill for building and maintaining a persistent, Obsidian-compatible knowledge wiki in the current working directory. The wiki is a compounding artifact — each source ingested produces 10–15 file updates across entity, concept, source, and synthesis pages, with maintained cross-references and a chronological log. The skill does the bookkeeping; the user curates sources and asks questions.

## Activation routing

When triggered, do this in order before responding to the user's actual request:

1. **Probe** — resolve the wiki root, then check for an existing wiki. Work through these in order and stop at the first hit:
   a. If `CLAUDE.md` exists in CWD, scan it for a `## Wiki` section. If that section contains a path (e.g. `wiki lives at ./Some Folder/` or `wiki-path: ./Some Folder/`), set `WIKI_ROOT` to that path. **Honour any scope gate the section states** — a pointer may declare it applies only to certain roots.
   b. Otherwise, if `./wiki-schema.md` exists, set `WIKI_ROOT = .` (current directory).
   c. Otherwise, **glob one level down for `*/wiki-schema.md`**. Exactly one match → set `WIKI_ROOT` to that folder. Several matches → ask which. **A brain living in a subfolder is the norm, not the exception — never conclude "no wiki" until this check also comes up empty.**
   d. Only if a, b, and c all miss, set `WIKI_ROOT = .` and treat the wiki as genuinely absent.
   e. Check whether `<WIKI_ROOT>/wiki-schema.md` exists.

   **Bootstrap is destructive-by-surprise if this probe is wrong** — it scaffolds `index.md`, `log.md`, and folders into `WIKI_ROOT`. Scaffolding over a populated repo root because a subfolder brain went undetected is the failure mode step (c) exists to prevent. Step (c) lowers the odds of a wrong verdict; the Bootstrap **Step 0 safety gate** is the independent backstop that makes a wrong verdict *harmless* — it refuses to scaffold into a populated target no matter what this probe concluded.
2. **If absent** → run the **Bootstrap workflow** (below).
3. **If present** → read `<WIKI_ROOT>/wiki-schema.md` to load domain-specific conventions (folder overrides, custom page types, house style). Then route the user's request:
   - "ingest / add this / I read / process this source" → **Ingest workflow**
   - "what does the wiki say / explain / compare / who is / what is / summarize" → **Query workflow**
   - "lint / health-check / find contradictions / find orphans" → **Lint workflow**
   - Ambiguous → ask once.

All subsequent file reads and writes use `WIKI_ROOT` as the base path, not necessarily CWD.

Never invent or rename files. If the user references something that doesn't exist, ask before creating.

---

## Bootstrap workflow

Run once per wiki, when `<WIKI_ROOT>/wiki-schema.md` is absent.

**Step 0 — Safety gate (MANDATORY — nothing gets scaffolded until this is clear).**
Bootstrap writes `index.md`, `log.md`, folders, and (Step 2b) edits to `CLAUDE.md`/`STATUS.md`.
If the probe was wrong — a subfolder brain missed, a `## Wiki` pointer never backfilled — those
writes land on top of unrelated work. This gate does **not** trust the probe's verdict; it
inspects the final `WIKI_ROOT` on disk and fails *safe*. Evaluate it now against `WIKI_ROOT` as
resolved so far, and **again at Step 2** against the final path if Step 1's interview changed it.

- **Safe → scaffold normally:** `WIKI_ROOT` does not exist yet, or exists and is empty.
- **Unsafe → STOP, write nothing:** `WIKI_ROOT` exists and is non-empty — in particular if it
  holds a `.git/` (a repo root), a `CLAUDE.md` (a project root), or any file this Bootstrap did
  not create.

On **Unsafe**, scaffold nothing. Show the user what `WIKI_ROOT` already contains, then ask once
(single AskUserQuestion):
- **Scaffold into a subfolder instead** (recommended) — offer `./<Name> Wiki Brain/`;
- **Scaffold here anyway** — explicit override, proceed into the populated folder;
- **Abort** — create nothing.

Proceed past this gate only on the user's explicit choice. A guard that refuses to write into a
populated target survives an incorrect probe; detection alone cannot.

**Step 1 — Interview** (single AskUserQuestion call, 2–4 questions max):
- *What is this wiki for?* (research topic, project domain, book companion, personal journal, etc.)
- *What kind of sources will dominate?* (papers, articles, transcripts, notes, code, mixed)
- *Any page types beyond the defaults (source, entity, concept, synthesis)?*
- *House style preference?* (terse summaries vs detailed; first-person notes vs neutral)
- *Where should the wiki folder live?* — ask this only if `CLAUDE.md` exists in CWD and does NOT already contain a `## Wiki` section. Offer a sensible default like `./<Project Name> Wiki Brain/` derived from the CWD folder name. Omit this question if CLAUDE.md is absent (scaffold into CWD as before) or if a path is already set.

**Step 2 — Scaffold** into `WIKI_ROOT` (the path chosen in Step 1, or CWD if no CLAUDE.md):

**Precondition — the Step 0 safety gate must be clear for the *final* `WIKI_ROOT`.** If Step 1's
interview selected or changed the path, re-run the gate against it now. Never write a file into a
non-empty target the gate has not cleared.

```
<WIKI_ROOT>/
├── README.md            (copy from ~/.claude/skills/s.wiki/templates/README.md — vault setup + command reference for the user)
├── wiki-schema.md       (copy from ~/.claude/skills/s.wiki/templates/wiki-schema.md, fill in interview answers)
├── index.md             (copy from ~/.claude/skills/s.wiki/templates/index.md)
├── log.md               (copy from ~/.claude/skills/s.wiki/templates/log.md)
├── raw/                 (with .gitkeep)
├── sources/             (with .gitkeep)
├── entities/            (with .gitkeep)
├── concepts/            (with .gitkeep)
├── syntheses/           (with .gitkeep)
└── assets/              (with .gitkeep)
```

If `WIKI_ROOT` is a subfolder of CWD, create it first if it doesn't exist.

The `README.md` is for the human user — explains the folder structure, how to invoke the skill, common commands, and Obsidian setup. Copy the template verbatim; no per-wiki customization needed on bootstrap. Safe for the user to edit afterwards; the skill never overwrites it.

**Step 2b — Wire the three-tier memory** (only when WIKI_ROOT ≠ CWD, i.e. a real project with a `CLAUDE.md`):

Append a `## Wiki` section to `CLAUDE.md` in CWD:
```markdown
## Wiki (Knowledge Base)

The project wiki lives at **`<WIKI_ROOT>`**. When the wiki skill activates from the project root, probe `<WIKI_ROOT>/wiki-schema.md`. All wiki file paths are relative to that folder root.
```
This makes all future activations from the project root automatically resolve to the correct subfolder — no `cd` needed.

Then wire the working-memory tier (see the global `## Memory architecture` contract — CLAUDE.md = stable, STATUS.md = live, wiki = long-term):
- **Scaffold `STATUS.md` at CWD** (the project root, **not** WIKI_ROOT) from `~/.claude/skills/s.wiki/templates/status.md` — **only if it does not already exist** (never clobber an existing STATUS.md). Fill `<Project Name>` from the CWD folder name and the dates with today.
- **Append a thin `## Memory` pointer** to `CLAUDE.md` in CWD (once; skip if already present):
```markdown
## Memory

- Stable contract + rules: the global `CLAUDE.md` operating contract (see its `## Memory architecture`).
- **Live status — read `STATUS.md` first** for "where are we now"; any "current state" below is a snapshot and goes stale.
- Long-term domain knowledge: the wiki brain at **`<WIKI_ROOT>`**.
```

**Step 3 — Confirm** by listing what was created and pointing the user at `wiki-schema.md` to read/edit. Tell them: edit the schema any time to refine how the wiki specializes; the skill re-reads it on every activation.

**Step 4 — Append bootstrap entry to log.md**:
```
## [YYYY-MM-DD HH:MM] bootstrap | <wiki purpose from interview>
```

Do not pre-populate any content pages. Bootstrap is purely structural. The first ingest fills the wiki.

---

## Ingest workflow

Run when the user wants to add a source. The source may be: a file path, a URL, pasted text, an image, or "this conversation".

**Scope boundary — what belongs in a *project* brain.** A project wiki holds that project's
**domain knowledge** only. Do **not** ingest, and if encountered route elsewhere:
- Operator/personal facts or cross-project preferences about the user → harness memory (`~/.claude/…/memory/`), not the brain.
- Transferable, client-agnostic patterns/playbooks that generalize beyond this project → the global `cc-toolkit-wiki-brain`, not this project brain.
- Volatile "where are we now" state (current version, active task, next step) → `STATUS.md`, not the brain.

Keep the tiers clean: when a source mixes domain knowledge with any of the above, extract only the domain part here and flag the rest for its proper home.

**Step 1 — Read & confirm**:
- Place the raw source in `./raw/` if it isn't already (kebab-case filename).
- Read the source fully. For long sources, internally summarize key claims, entities, and concepts before proceeding.
- Briefly confirm with the user (2–3 bullet recap) what you extracted — give them a chance to redirect emphasis before you commit files.

**Step 2 — Write source summary** at `./sources/<kebab-title>.md` using `~/.claude/skills/s.wiki/templates/source.md`:
- Required YAML frontmatter: `type: source`, `tags`, `raw: [[raw/...]]`, `date_ingested`, `date_published`, `author`, `status: stable`
- Body sections: Overview (2–4 sentence neutral summary), Key claims (each with inline `[[wikilinks]]` to relevant entities/concepts), Open questions, Contradictions with existing wiki (flagged explicitly)

**Step 3 — Update existing pages** the source touches:
- Read each `[[wikilink]]` target. If it exists, append/revise. If absent and the entity/concept is significant, create a new page from the appropriate template.
- Every new claim added to an existing page must carry an inline `[[sources/<source-slug>]]` citation.
- If a new source contradicts an existing claim, **do not silently overwrite**. Flag both versions on the affected page under a `## Contested` section and set `status: contested` in frontmatter.

**Step 4 — Update `index.md`** to reflect new and modified pages. Bump its `Last updated` field.

**Step 5 — Append to `log.md`**:
```
## [YYYY-MM-DD HH:MM] ingest | <source title>
- Source: [[sources/<slug>]]
- New pages: [[entities/...]], [[concepts/...]]
- Updated: [[entities/...]], [[concepts/...]]
- Contradictions: (if any)
```

**Step 6 — Report back** to the user: list files created + modified with link paths so they can open them in Obsidian.

---

## Query workflow

Run when the user asks the wiki something.

**Step 1 — Find**: read `./index.md` to locate candidate pages. Read those pages fully. Follow `[[wikilinks]]` one hop where useful. Read `./wiki-schema.md` for any domain-specific routing hints.

**Step 2 — Synthesize**: produce the answer in markdown. **Every non-trivial claim must carry an inline citation** to either a `[[sources/...]]` page or a `[[concepts/...]]` page that itself cites sources. If the wiki is silent on something, say so explicitly — never improvise unsourced facts.

**Step 3 — Offer to file** (default yes for non-trivial questions): "Want me to file this as `./syntheses/<slug>.md` so it compounds?" If yes:
- Use `~/.claude/skills/s.wiki/templates/synthesis.md`
- Frontmatter must include `query: "<the original question>"`, `sources: [[...]]`, `updated:`, `status: stable`
- Add to `index.md` under Syntheses
- Append a log entry: `## [YYYY-MM-DD HH:MM] query | <question>`

Skip the filing offer for trivial lookups ("what's the date on the Bush paper?", "list all sources tagged X").

---

## Lint workflow

Run when the user explicitly asks for a health check. Lint is **not** automatic.

Walk the wiki and produce a prioritized markdown report (to chat, not filed) covering:

1. **Contradictions** — pages with `status: contested` or `## Contested` sections still unresolved.
2. **Stale claims** — pages where `updated:` is older than the most recent source on the same topic.
3. **Orphan pages** — `.md` files with zero inbound `[[wikilinks]]` (excluding `index.md`, `log.md`, `wiki-schema.md`).
4. **Missing pages** — `[[wikilink]]` references pointing to nonexistent files.
5. **Frontmatter drift** — pages missing required keys (`type`, `tags`, `sources`, `updated`, `status`).
6. **Index drift** — files on disk not in `index.md`, or `index.md` entries pointing to nonexistent pages.
7. **Log gaps** — ingests implied by source `date_ingested` but absent from `log.md`.
8. **Topic gaps** — concepts/entities mentioned across 3+ sources but lacking their own page (promotion candidates).

**Do not auto-fix.** Propose; let the user choose what to address.

Append log entry: `## [YYYY-MM-DD HH:MM] lint | <n> findings`.

Full lint heuristics, output format, and edge cases: see `~/.claude/skills/s.wiki/reference/lint-checks.md`.

---

## Conventions

### Wikilinks
- Always use full relative path: `[[entities/Vannevar-Bush]]`, not bare `[[Vannevar-Bush]]`. This survives folder renames.
- Kebab-case filenames: `memex-as-knowledge-trail.md` → `[[concepts/memex-as-knowledge-trail]]`.
- Display text override sparingly: `[[entities/vannevar-bush|Bush]]` only when prose flow demands it.

### YAML frontmatter (required on every wiki page)
```yaml
---
type: source | entity | concept | synthesis
tags: [tag-one, tag-two]
sources: [[sources/...]]   # empty list for source pages themselves
updated: YYYY-MM-DD
status: draft | stable | stale | contested
---
```
Source pages add: `raw:`, `date_published:`, `author:`, `date_ingested:`. Synthesis pages add: `query:`.

### Log format (strict — keeps grep working)
```
## [YYYY-MM-DD HH:MM] <op> | <subject>
```
- `op` ∈ {`bootstrap`, `ingest`, `query`, `lint`, `manual`}
- One blank line between entries.

### Citations (provenance)
- Every non-trivial factual claim gets an inline `[[sources/...]]` reference next to it.
- Every page ends with a `## Sources` section listing all referenced sources (deduped).
- "Non-trivial" = anything an outside reader couldn't verify by general knowledge.

### Status field semantics
- `draft` — under active editing, not yet vetted
- `stable` — reviewed, no known issues
- `stale` — newer sources have superseded; needs review
- `contested` — sources disagree; see `## Contested` section on the page

---

## Templates

When creating new pages, copy from these:
- `~/.claude/skills/s.wiki/templates/source.md`
- `~/.claude/skills/s.wiki/templates/entity.md`
- `~/.claude/skills/s.wiki/templates/concept.md`
- `~/.claude/skills/s.wiki/templates/synthesis.md`

For bootstrap:
- `~/.claude/skills/s.wiki/templates/wiki-schema.md`
- `~/.claude/skills/s.wiki/templates/index.md`
- `~/.claude/skills/s.wiki/templates/log.md`
- `~/.claude/skills/s.wiki/templates/status.md` (scaffolded to the project root as `STATUS.md`, not into the brain — see Step 2b)

---

## Out of scope (belongs in a plugin, not this skill)

- File watcher on `raw/` for auto-ingest on file drop
- Scheduled lint passes (cron / loop)
- MCP-exposed wiki search tool (use a flat `index.md` read until scale demands it)
- Image extraction pipelines (Obsidian's web clipper + download hotkey handles this manually)

See `~/.claude/skills/s.wiki/reference/obsidian-tips.md` for ergonomic add-ons (Web Clipper, Dataview, Marp, graph view, git).
