---
type: harness
tags: [skills, s.wiki, s.wrap-up, s.goal-run, s.ship-cc-tlkit, s.venv-setup, obsidian, catalog]
origin: GKT cc-toolkit (harness process mapping, 2026)
updated: 2026-07-21
status: stable
---

# Skills Catalog

What each global skill (`~/.claude/skills/`, deployed by `cc-toolkit`) does, what triggers it,
and its internal flow. Five user-authored skills plus one installed plugin bundle.

## `s.wiki` — the wiki engine

**Triggers:** "set up a wiki", "ingest this into my wiki/notes/brain", "what does the wiki
say about X", "health-check the wiki", explicit `/s.wiki`.

Four workflows, routed by request shape once a wiki is found (probes `<WIKI_ROOT>/wiki-schema.md`):

| Workflow | When | Does |
|---|---|---|
| **Bootstrap** | `wiki-schema.md` absent | One `AskUserQuestion` interview (purpose, source profile, page types, house style) → scaffolds folder structure + `wiki-schema.md` + `index.md` + `log.md` → wires the three-tier convention (`STATUS.md`, `CLAUDE.md` pointers) if a real project |
| **Ingest** | "add this source" | Reads source → confirms extraction with user → writes `sources/<slug>.md` → updates touched entity/concept pages with inline `[[wikilinks]]` citations → flags contradictions rather than silently overwriting → updates `index.md` + `log.md` |
| **Query** | "what does the wiki say about X" | Reads `index.md` → follows wikilinks one hop → synthesizes an answer with citations → offers to file as a `syntheses/` page (skippable for trivial lookups) |
| **Lint** | explicit health-check request only, never automatic | Reports contradictions, stale claims, orphan pages, missing wikilink targets, frontmatter drift, index drift, log gaps, topic-gaps (concepts mentioned 3+ times but no page) — proposes, never auto-fixes |

This is the engine behind every wiki brain in this ecosystem, including this one — the
global `cc-toolkit-wiki-brain` is itself an `s.wiki` vault, scoped by its own
[[../wiki-schema]].

## `s.wrap-up` — end-of-session ritual

**Triggers:** "wrap up", "end of session", "update CLAUDE.md", "commit message", `/s.wrap-up`.

Runs mostly autonomously; **exactly one approval gate**. Never runs `git add`/`commit`/`push`
itself — staging and pushing stay manual.

1. **Orient (silent):** detect codebase vs. notes-based project. For a codebase, read
   `git status`/unpushed log/diff-stat, and **read every non-trivial diff in full** (a single
   file's diff often bundles several unrelated bodies of work). Read `CLAUDE.md` and
   `STATUS.md` if present.
2. **Wiki note (no gate):** if a wiki exists, write a `syntheses/<date>-session-<slug>.md`
   note directly — covering every distinct body of work found, not just the headline task.
3. **The one gate — a layman's summary in three parts:**
   - **A** — what changed this session (from the diff/tool-call record, never from memory).
   - **B** — what will change in `CLAUDE.md`/`STATUS.md` (respecting the tier split: volatile
     state → `STATUS.md` if it exists, stable rules → `CLAUDE.md`).
   - **C** — promote candidates to `cc-toolkit-wiki-brain` (flag-only, never auto-applied —
     this is the mechanism that feeds the global brain from every project).
4. **On confirmation:** writes the tier files, drafts a copy-paste commit message matching
   the project's existing style, tells the user the re-anchor point for next session (prefers
   `STATUS.md`).

## `s.goal-run` — autonomous execution of an existing plan

**Triggers:** "run this until done", execute an existing backlog item/audit/tiered plan
autonomously, explicit `/s.goal-run`. **Does not invent scope** — if no concrete plan exists,
it says so rather than improvising one.

**Exactly one approval gate** (the goal-setup interview), then runs unattended via `/loop`
dynamic mode until done or blocked. Hard, permanent boundaries regardless of setup answers:
never merge, never push, never force, never delete files — always separate manual asks.

1. **Orient:** identify the target plan, read it in full (treating stale line/function
   references as hypotheses to re-verify, not facts), and — critically — run a **live-counterpart
   safety recon**: is there a running/deployed instance of this codebase that constrains what's
   safe to test mid-run? If so, live launches are barred from the loop and reserved for one
   supervised step afterward.
2. **Goal-setup interview (the one gate):** scope, isolation (branch/worktree), commit
   cadence, verification style, guardrails (quoted verbatim from project docs), durable
   checkpoint location.
3. **Persist the spec** into the checkpoint location + a `TodoWrite` list — survives context
   compression mid-run.
4. **Execution loop**, per item: locate → implement → verify → commit (named files only, never
   `-A`) → checkpoint. Self-paced via `/loop` + `ScheduleWakeup`.
5. **Close-out:** full verification pass across all changed files together, closing summary,
   hands off to `s.wrap-up` for session bookkeeping — does not duplicate it.

## `s.ship-cc-tlkit` — the cc-toolkit release conductor

**Triggers:** "ship the toolkit", "ship cc-toolkit", "release the toolkit", "close out cc-toolkit",
explicit `/s.ship-cc-tlkit`. **cc-toolkit-specific** — deployed globally but guarded to the toolkit
loop; it refuses to run anywhere else (the one project with a deploy-down step).

The single-pass close-out for a cc-toolkit session: it *conducts* the round-trip that used to be a
prose runbook an agent had to remember — the source of the self-description-drift
([[../incidents/2026-07-16-self-description-drift]], Failure 3). **Exactly one approval gate** (the
consolidated round-trip summary); everything before it is reversible working-tree state, so aborting
there ships nothing.

1. **Guard (silent):** resolve the repo via `$env:CC_TOOLKIT_HOME`; refuse-and-explain if it is
   unset or the target isn't a cc-toolkit clone. All ops run against that repo explicitly, whatever
   the session CWD.
2. **Harvest UP:** `setup.ps1 -Harvest` dry-run → `-Harvest -Force` — the session's `~/.claude` edits
   become visible to git in the clone's working tree.
3. **Author docs in the repo:** reuses `s.wrap-up`'s orientation + wiki-note steps (by reference, not
   duplicated), bound to CWD = the clone, so the session note + `STATUS.md` land directly in the
   repo. Kills the old second harvest; `STATUS.md` is written **state + intent only, never SHAs**.
4. **The one gate:** the files to stage **by name**, the commit message, and an explicit push +
   deploy statement — replaces `s.wrap-up`'s own gate.
5. **On confirm:** stage named files (never `-A`) → commit → push; stop on a failed push. Report
   harvested-but-unstaged noise (`settings.json`) as an open thread.
6. **Deploy DOWN:** `setup.ps1 -Force` — the fresh commit (incl. the session note) rides back to
   `~/.claude`, so the copy `s.wiki` queries is never stale.

Hard boundaries: never `git add -A`, force-push, merge, delete files, touch secrets, or run outside
the toolkit loop.

## `s.venv-setup` — Python venv setup for any project

**Triggers:** "set up a venv", "initialize a Python project environment", "create a virtual
environment", explicit `/s.venv-setup`.

Thin wrapper — all logic lives in the bundled `scripts/new-pyproject.ps1`, which this skill
locates (two levels up from its own base directory, since `scripts/` and `skills/` are sibling
deployed folders) and runs against the current project folder. Creates `.venv`, scans the
project's actual imports to install/sync `requirements.txt` (adds new, removes stale), and adds
`.gitignore` + VS Code interpreter config. Idempotent — safe to re-run on a project that already
has a `.venv`. Windows/PowerShell only. See
[[../playbooks/venv-setup-workflow]] for the full mechanics and gotchas.

## `obsidian@obsidian-skills` — installed plugin bundle

**Source:** marketplace `kepano/obsidian-skills`, installed user-scope. Five skills, no
agents, no commands:

| Skill | Does |
|---|---|
| `defuddle` | Extracts clean markdown from web pages via the Defuddle CLI (used instead of `WebFetch` for articles/docs) |
| `json-canvas` | Creates/edits `.canvas` files — nodes, edges, groups, connections |
| `obsidian-bases` | Creates/edits `.base` files — database-like views with filters/formulas |
| `obsidian-cli` | Drives an Obsidian vault from the CLI — notes, tasks, properties, plugin/theme dev |
| `obsidian-markdown` | Obsidian-flavored markdown — wikilinks, embeds, callouts, properties |

These are general Obsidian ergonomics, not specific to any one wiki brain — they apply
equally to this global brain and any project brain `s.wiki` scaffolds.

## Related
- [[memory-architecture]] — `s.wiki` is the engine behind the three-tier convention's long-term layer
- [[harness-overview]] — where these skills sit in the overall tooling map
