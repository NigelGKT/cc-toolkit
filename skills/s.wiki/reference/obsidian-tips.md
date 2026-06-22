# Obsidian Ergonomic Add-ons

Optional tooling that makes working with a wiki-skill-managed vault more pleasant. None of these are required — the skill produces a clean folder of markdown files that works in any editor.

---

## Open the wiki as an Obsidian vault

1. Obsidian → "Open folder as vault" → point at the folder containing `wiki-schema.md`.
2. Settings → Files and links → "Default location for new attachments" → set to `assets/`.
3. Settings → Files and links → "Use Wikilinks" → ON (default).
4. Settings → Files and links → "New link format" → "Relative path to file" (matches the skill's convention).

---

## Web Clipper

Browser extension. Converts web articles to markdown and saves to your vault.

- Install: search "Obsidian Web Clipper" in Chrome/Firefox/Edge extension store.
- Configure save location → `raw/` of your wiki vault.
- After clipping, ask the wiki skill: *"ingest the article I just clipped at raw/<filename>.md"*.

---

## Image handling for clipped articles

Web Clipper leaves images as URLs by default — fine for online viewing, but they rot.

1. Settings → Files and links → Attachment folder path: `assets/`
2. Settings → Hotkeys → search "Download attachments for current file" → bind `Ctrl+Shift+D`
3. After clipping an article, hit the hotkey — referenced images download to `assets/` and the markdown rewrites to local paths.

**Note:** Claude doesn't natively read markdown with inline images in a single pass. If a source has critical images, mention them to the skill explicitly and it'll view them as separate attachments.

---

## Dataview plugin

Reads YAML frontmatter and produces dynamic tables and lists. The wiki skill's frontmatter convention is Dataview-ready out of the box.

**Install:** Settings → Community plugins → browse → "Dataview" → install + enable.

**Example queries** to paste in any wiki page:

Recent sources:
```dataview
TABLE author, date_published, status
FROM "sources"
SORT date_ingested DESC
LIMIT 10
```

All contested pages:
```dataview
LIST
FROM ""
WHERE status = "contested"
```

Entities with no inbound sources:
```dataview
LIST
FROM "entities"
WHERE length(sources) = 0
```

---

## Graph view

`Ctrl+G` (or the graph icon in the left rail). Shows the wiki as a node-edge graph — invaluable for spotting hub pages (highly-connected concepts), orphans (isolated nodes), and clusters (emergent sub-topics).

Tip: use the local graph (`Ctrl+Shift+G` on an open page) to see just that page's neighborhood.

---

## Marp (slide decks)

Plugin: "Marp slides preview". Turns a wiki page with `marp: true` frontmatter into a slide deck — useful for synthesizing a query result as a presentation.

Ask the skill: *"file this query as a synthesis with Marp frontmatter so I can present it."*

---

## Git version control

The wiki is just a folder of markdown. Run `git init` in the wiki root and you get:
- Full version history (every ingest is a diff you can roll back)
- Branching (try a reorganization on a branch, merge or discard)
- Sync across machines via a private GitHub/GitLab repo
- A way to share a wiki with collaborators

Recommended `.gitignore`:
```
.obsidian/workspace*
.obsidian/cache
.trash/
```

Optional: have the skill commit after each ingest by asking *"commit after ingesting"*.

---

## Templater (manual editing)

If you find yourself manually creating pages outside the skill (e.g. quick notes), the Templater plugin wraps the templates in `~/.claude/skills/wiki/templates/` for one-keystroke insertion.

The wiki skill itself doesn't need this — it creates pages programmatically. Templater is purely for when you want to bypass the skill and edit by hand.

---

## Quick reference card

| Need to... | Do this |
|---|---|
| Add a source | Drop file in `raw/`, ask skill to ingest |
| Quick lookup | Just ask the skill — it routes to the query workflow |
| See connections | Obsidian graph view (`Ctrl+G`) |
| Find stale pages | Ask the skill to lint |
| Find recent activity | `grep "^## \[" log.md \| tail -20` |
| List all sources by year | Dataview query (see above) |
| Roll back a bad ingest | `git revert <commit>` (if git is set up) |
