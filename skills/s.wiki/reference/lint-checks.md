# Lint Checks

Comprehensive catalog of health checks the wiki skill runs during a lint pass. The skill's `Lint workflow` section in `SKILL.md` lists these by name; this file is the deep reference with heuristics and edge cases.

Lint is never automatic — only fires on explicit user request.

---

## 1. Contradictions

**What to flag:**
- Pages with `status: contested` in frontmatter that haven't been resolved
- Pages containing a `## Contested` section
- Pages where two cited sources make opposing claims about the same fact (even if `status` is still `stable` — the contradiction may have been missed)

**Severity:** High. Data integrity issue.

**Heuristic for detection:** scan all source pages for `Contradictions with existing wiki` sections that reference still-existing pages, and check whether those target pages reflect the contradiction.

---

## 2. Stale claims

**What to flag:**
- Pages where `updated:` predates the most recent source on the same topic (matched by shared tags or shared sources)
- Pages with `status: stale` not yet revised

**Severity:** Medium. The page may still be correct, but needs review.

**Heuristic:** for each page, find the newest `date_ingested` among sources that share at least one tag. If that date > page's `updated`, flag.

---

## 3. Orphan pages

**What to flag:**
- `.md` files with zero inbound `[[wikilinks]]` from any other page

**Exceptions** (always allowed as roots — never flag as orphans):
- `index.md`
- `log.md`
- `wiki-schema.md`

**Severity:** Low. Either the page should be linked from somewhere, or it should be archived/deleted.

**Heuristic:** build the link graph, find nodes with in-degree zero, subtract exceptions.

---

## 4. Missing pages

**What to flag:**
- `[[wikilink]]` references pointing to files that don't exist on disk

**Severity:** High. Either the link is broken (typo, rename) or the page should exist and was forgotten.

**Heuristic:** extract all `[[...]]` references, resolve to file paths, check existence. Group by missing target so the user sees how many pages reference each missing page (heavily-referenced gaps are highest priority).

---

## 5. Frontmatter drift

**What to flag:**
- Required keys missing on any wiki page: `type`, `tags`, `sources`, `updated`, `status`
- Type-specific required keys missing:
  - `source` pages: `raw`, `date_published`, `author`, `date_ingested`
  - `synthesis` pages: `query`
- Invalid `status` values (must be one of: `draft`, `stable`, `stale`, `contested`)
- Invalid `type` values (unless extended in `wiki-schema.md`)

**Severity:** Medium. Breaks Dataview queries and confuses future ingest passes.

---

## 6. Index drift

**What to flag:**
- `.md` files on disk (in `sources/`, `entities/`, `concepts/`, `syntheses/`) not present in `index.md`
- `index.md` entries pointing to files that no longer exist

**Severity:** Medium. The index is the skill's primary navigation tool — drift makes queries miss content.

**Heuristic:** diff the file system against the index entries. Both directions matter.

---

## 7. Log gaps

**What to flag:**
- Source pages with `date_ingested:` but no matching `## [<date>] ingest |` entry in `log.md`
- Log entries referencing pages that no longer exist
- Time-jumps in the log (gaps > 30 days during what should have been active use) — soft signal worth surfacing

**Severity:** Low. The log is a forensic tool, not a data store — gaps don't break functionality but they erode trust.

---

## 8. Topic gaps

**What to flag:**
- Concepts/entities mentioned across 3+ sources but lacking their own page
- Sources that introduce a named idea/person and don't get a corresponding entity or concept page

**Severity:** Low (suggestion, not error). These are promotion candidates — concepts that have earned their own page through repeated mention.

**Heuristic:** scan all source page bodies for repeated capitalized phrases or quoted terms that don't resolve to existing `[[wikilinks]]`. Cluster by surface form. 3+ mentions across distinct sources = strong candidate.

---

## 9. Wikilink hygiene

**What to flag:**
- Bare `[[Entity-Name]]` references without folder prefix (should be `[[entities/Entity-Name]]`)
- Display-text aliases where the display text doesn't match the target page title (likely stale rename)
- Inconsistent slug capitalization across pages

**Severity:** Low (cosmetic but compounds over time).

---

## 10. Tag drift

**What to flag:**
- Tags used inconsistently across pages (e.g. `obsidian` vs `Obsidian` vs `obsidian-app`)
- Singleton tags used only once — consider merging into a broader tag
- Tags on `concept`/`entity` pages that don't appear on any source page (likely the concept tag should be a sub-tag of a source tag)

**Severity:** Low.

---

## Lint output format

Present findings as a prioritized markdown checklist in chat (do not file as a synthesis):

```
# Lint report — YYYY-MM-DD

**Wiki:** <pwd basename>  ·  **Pages scanned:** N  ·  **Issues found:** M

## High priority (data integrity)
- [ ] Missing page: `[[entities/Vannevar-Bush]]` referenced in 3 places but file does not exist
- [ ] Contradiction unresolved: `concepts/memex.md` — Bush 1945 vs Nelson 1965

## Medium priority (housekeeping)
- [ ] Orphan: `sources/random-podcast.md` has no inbound links
- [ ] Index drift: 2 files on disk missing from index.md
- [ ] Frontmatter drift: `entities/foo.md` missing `updated` key

## Low priority (style / suggestions)
- [ ] Topic gap candidate: "Annotation pipelines" mentioned in 4 sources, no page yet
- [ ] Tag drift: `obsidian` and `Obsidian` both used — merge?
- [ ] Bare wikilink: `[[Vannevar-Bush]]` in `concepts/memex.md` should be `[[entities/Vannevar-Bush]]`
```

**Do not auto-fix.** Always propose; let the user choose what to address. Some "issues" (e.g. orphan pages, singleton tags) are legitimate by design in some wikis — only the user can decide.

After the report, ask: "Want me to fix any of these?" and apply targeted fixes only to the items they pick.

Append log entry on completion:
```
## [YYYY-MM-DD HH:MM] lint | N findings (H high, M medium, L low)
```
