# Wiki — README

This folder is an Obsidian-compatible knowledge wiki, managed by the `s.wiki` Claude Code skill. Open the folder as a vault in Obsidian to browse; talk to Claude Code from your project workspace to add to it or query it.

---

## What's in here

| Path | Purpose |
|---|---|
| `wiki-schema.md` | Domain conventions — purpose, house style, custom page types, glossary. Edit anytime; the skill re-reads it every activation. |
| `index.md` | Catalog of every page in the wiki. |
| `log.md` | Chronological log of every operation (bootstrap, ingest, query, lint, manual). Grep-friendly. |
| `sources/` | Ingested source summaries — one page per conversation, doc, or paper. |
| `entities/` | People, places, organizations, things. |
| `concepts/` | Ideas, methods, definitions, models. |
| `syntheses/` | Filed answers to recurring questions. |
| `raw/` | Original source files before processing (transcripts, PDFs, etc.). |
| `assets/` | Images, screenshots, attachments. |
| *(custom folders)* | Any extras defined in `wiki-schema.md` (e.g. `decisions/`, `incidents/`, `backlog/`). |

---

## How to use it

You **don't need to be inside this folder** when talking to Claude Code. As long as `CLAUDE.md` in the project root has a `## Wiki` section pointing here, the skill resolves the path automatically.

### Activation

The skill triggers automatically on natural-language phrases, or explicitly with `/s.wiki`.

### Common commands

| What you want to do | What to say |
|---|---|
| **Add a source** | *"ingest HANDOFF.md into the wiki"*<br>*"add this source"*<br>*"process this conversation"* |
| **Ask a question** | *"what does the wiki say about X?"*<br>*"explain Y from the wiki"*<br>*"who is Z?"* |
| **Health check** | *"lint the wiki"*<br>*"health-check the wiki"*<br>*"find contradictions"* |
| **File something directly** | *"file L02 as a backlog page"*<br>*"add a decision page for X"* |

### What happens on each operation

- **Ingest** — Skill reads the source, gives you a 2–3 bullet recap as your checkpoint, then writes the source summary, creates or updates related entity/concept pages, refreshes the index, and appends to the log.
- **Query** — Skill reads relevant pages, synthesizes an answer with inline citations, and offers to file the answer as a `synthesis` page for compounding.
- **Lint** — Skill produces a report of orphans, contradictions, stale claims, broken wikilinks, and frontmatter drift. Never auto-fixes — you decide what to act on.

---

## First-time setup checklist

Tick these off once when you first open the vault. They keep the skill's link format and Obsidian's behaviour aligned — without them, things still work, but auto-suggestions and rename-updates will drift from the convention over time.

### 🔧 Obsidian settings → Files and links

- [ ] **Use `[[Wikilinks]]`**: ON
  *Matches the format the skill writes — `[[entities/foo]]`, not `[foo](entities/foo.md)`.*
- [ ] **New link format**: **Path from vault folder**
  *So auto-suggestions and rename-updates use the same full-path style the skill enforces. The other two options (Shortest path / Path from current file) will strip or warp the folder prefix.*
- [ ] **Automatically update internal links**: ON
  *Rename a page → every wikilink to it updates automatically. Without this, renames create dead links.*
- [ ] **Default location for new notes**: Same folder as current file
  *Keeps notes in the right folder when you create them by clicking a missing-page wikilink.*

### 🔌 Obsidian core plugins (Settings → Core plugins — most are on by default)

- [ ] **Backlinks** — see which pages link to the current one (essential for navigation)
- [ ] **Graph view** — visualise the wiki structure (genuinely useful after ~10 pages, press `Ctrl+G`)
- [ ] **Outline** — quick table of contents for the current page
- [ ] **Tags pane** — browse all tags across the vault

### 📄 Project / Claude Code

- [ ] `CLAUDE.md` in the project root has a `## Wiki` section pointing to this folder
  *The skill writes this automatically during bootstrap. Only check manually if you set up the wiki by hand.*

### ✅ Verification

- [ ] Open `wiki-schema.md` and `index.md` in Obsidian — both render with headers and YAML frontmatter visible
- [ ] Press `Ctrl+G` to open the Graph view — empty for now, but should load without error
- [ ] Type `[[wiki-schema` in any note — Obsidian should auto-suggest `wiki-schema.md` with the full path (confirms wikilink + path-format settings are correct)

---

## Maintenance rhythm

Low effort, high payoff. Nothing here is automatic — you trigger each one.

- **After every 5–10 ingests**, say *"lint the wiki"* or *"health-check the wiki"*. Surfaces orphan pages, contradictions, stale claims. Takes ~30 seconds; report comes back in chat; you decide what to fix.
- **Glance at `index.md`** occasionally for miscategorised or duplicate pages.
- **Read `log.md`** if you forget what's been added — every operation appends one grep-friendly line.

---

## Conventions worth knowing

- **Filenames are lowercase-with-hyphens** (`carried-float.md`, not `Carried Float.md`).
- **Wikilinks include the folder** (`[[entities/yk-chan]]`, not bare `[[yk-chan]]`).
- **Every non-trivial claim has an inline citation** — the skill enforces this, you don't need to write them manually.
- **Pages have YAML frontmatter** (the `---` block at the top) — also managed by the skill.
- **Lint never runs automatically** — ask for it periodically.

For the full list of conventions specific to this wiki, read `wiki-schema.md`.

---

## Where to look

| If you want to… | Open |
|---|---|
| Understand this wiki's specific conventions | `wiki-schema.md` |
| Browse what's been added | `index.md` |
| See what's been done recently | `log.md` (tail it) |
| Find the skill source | `~/.claude/skills/s.wiki/SKILL.md` |

---

*Generated automatically on bootstrap. Safe to edit — the skill won't overwrite this file.*
