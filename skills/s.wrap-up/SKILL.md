---
name: s.wrap-up
description: End-of-session wrap-up ritual for any project. Runs autonomously — writes a wiki session note (if a wiki exists), then presents ONE plain-English summary of all changes since the last push plus the planned CLAUDE.md edits; on a single confirmation it writes CLAUDE.md and drafts a copy-paste commit message. The user stages and pushes manually. Use when the user wants to wrap up, close out a session, update CLAUDE.md, or get a commit message. Triggers on phrases like "wrap up", "end of session", "update CLAUDE.md", "commit message", "let's wrap", "/s.wrap-up".
---

# Wrap-Up

End-of-session ritual. Runs **autonomously** through the wiki note and a single plain-English summary, takes **one** confirmation, then writes CLAUDE.md and drafts the commit message. The only manual steps are the user's: staging, committing, pushing. This skill never runs `git commit`/`git add`/`git push`.

There is exactly **one approval gate** in the whole flow: the layman's summary in Stages 1–3. Do not invent additional gates — do not ask permission to write the wiki note, do not ask before reading diffs, do not ask "should I proceed?" at each stage.

---

## On activation — orient + thoroughness self-check (MANDATORY, silent)

Do all of this silently before presenting anything.

0. **Detect project type**: run `git rev-parse --is-inside-work-tree` (suppress errors). If it succeeds, this is a **codebase wrap-up** — proceed with steps 1-2 as written. If it fails (not a git repo), this is a **notes-based wrap-up** — skip steps 1-2 entirely and instead:
   - Review this session's actual file operations (Write/Edit/Bash tool calls) as the authoritative source of truth — **NEVER summarise from memory alone**. There's no diff to read, so the running conversation's tool-call record is the equivalent source: walk back through it and list every file touched.
   - List every file created, moved, or edited this session, grouped by distinct body of work.
1. *(Codebase only)* `git log --oneline -20` — learn the commit message style (prefix/scope, version numbering) and recent history shape.
2. *(Codebase only)* **Capture everything unpushed — this is the authoritative source of truth. NEVER summarise from in-session memory.**
   - `git status` — staged, unstaged, untracked.
   - `git log --oneline @{u}..HEAD` — local commits not on the remote (fallback `HEAD~5..HEAD` if no upstream).
   - `git diff --stat @{u}` — every changed file with line counts (fallback `git diff --stat HEAD`).
   - **For every non-trivial file in that stat, READ its actual diff** (`git diff @{u} -- <file>`), not just the stat line. A large diff in a single file routinely bundles **multiple unrelated bodies of work** from parallel sessions — you will miss them if you only read the files you personally touched this session.
3. Read `CLAUDE.md` in CWD fully if present — note version, backlog, versioning convention.
3b. Read `STATUS.md` in CWD if present — it is the live working-memory tier (current version, active task, next step). When it exists, it is the authoritative "where were we" anchor and the target for volatile updates in the write stage.
4. Check for a wiki: probe `./wiki-schema.md` or scan `CLAUDE.md` for a `## Wiki` section pointing to a subfolder.

**THOROUGHNESS SELF-CHECK — answer these explicitly before moving on:**
- **Codebase**: Did I read every non-trivial diff, or only the changes I remember making this session? Does any single file's diff contain several *distinct* changes (a feature + a refactor + a rename) that I'd otherwise lump into one vague line? List each separately. Are any untracked files/folders real work (docs, plans, notes) rather than runtime data?
- **Notes-based**: Did I account for every file operation this session, not just the ones tied to the main headline task? Does any single file's edits contain several *distinct* changes I'd otherwise lump into one vague line? List each separately.
- Enumerate the **distinct bodies of work** as a list. If that list came from memory rather than the diffs/tool-call record, STOP and re-derive it from source.
- Did anything this session **generalize beyond this project** — a reusable command/skill, a global CLAUDE.md rule, or a client-agnostic lesson? Note it for the promote step (Part C).

This self-check is the fix for the single most common failure of this skill: under-reporting because the summary was written from memory instead of the diff (or, for notes-based projects, the tool-call record).

---

## Stage 0 — Wiki session note (write directly, NO gate)

If a wiki exists, **write the note directly — do not ask first.** Cover **all** bodies of work enumerated in the self-check, not just the current session's headline change.

Write a new page at `<WIKI_ROOT>/syntheses/<YYYY-MM-DD>-session-<slug>.md`:

```markdown
---
type: synthesis
tags: [session-note]
sources: []
updated: YYYY-MM-DD
status: stable
query: "Session note — <brief topic>"
---

# Session Note — <Date> — <Brief Topic>

## What was attempted
(1–3 sentences)

## What shipped
(every concrete body of work: files modified, features added, bugs fixed — one bullet each)

## What was deferred
(anything explicitly left for a future session)

## Open threads
(questions or decisions raised but not resolved)
```

Keep the body tight (~10 lines, but never drop a real body of work to hit that). Append to `<WIKI_ROOT>/log.md`:
```
## [YYYY-MM-DD HH:MM] ingest | Session note — <topic>
```
Update `<WIKI_ROOT>/index.md` under Syntheses.

If no wiki exists, skip silently.

---

## Stages 1–3 — Layman's summary → one gate → implement → commit draft

Present ONE plain-English summary, take a single confirmation, then implement CLAUDE.md and draft the commit message in the same follow-up.

### The summary (present this, then stop for the one confirmation)

Plain English — what a non-engineer could follow. No code-path dumps. Two short parts:

**A — What changed this session.** *(Codebase: since the last push, from the diff. Notes-based: every file created/moved/edited this session, from the tool-call record.)* The distinct bodies of work from the self-check (each as its own bullet, even when several live in one file), which files they touch, and — **codebase only** — how many unpushed commits exist. Flag anything that looks like it shouldn't be committed (`.env`, large binaries, temp files), and anything reverted.

**B — What I'll change in CLAUDE.md / STATUS.md.** Respect the three-tier split (see the global `## Memory architecture`): **if a `STATUS.md` exists at the project root**, the volatile working state goes there — current version, what just shipped, active task, next step — and CLAUDE.md gets only *stable* edits (architecture/data-flow notes, key-files table, config section, contract changes). **If there is no STATUS.md**, everything goes into CLAUDE.md as before (single-tier fallback). Either way: surgical edits, be explicit about what you are **not** touching, and do not infer changes that aren't in the diff.

**C — Promote to the global toolkit (cc-toolkit)?** Anything from this session that generalizes beyond this project: a reusable command → `commands/`, a skill → `skills/`, a refined global behaviour → global `CLAUDE.md`, a **transferable pattern/concept → `cc-toolkit-wiki-brain/concepts/`**, or a **client-agnostic lesson/checklist → `cc-toolkit-wiki-brain/playbooks/`**. List each as a one-line candidate with its target. For anything going into `cc-toolkit-wiki-brain/`, note that promotion means **scrub project specifics from the body and record the source in `origin:` frontmatter** (see `cc-toolkit-wiki-brain/wiki-schema.md`). **Flag-only:** never auto-push to cc-toolkit and never add a gate for it — the user promotes manually. If nothing generalizes, say "nothing to promote" and move on.

Then ONE gate, one sentence: *"Confirm to apply, or flag anything to fix."*

### On confirmation

Run straight through — no further gates:
1. Write the changes per the tier split from Part B: refresh `STATUS.md` with the volatile state (bump its `Last updated:`, update Latest / Active task / Next step) **if it exists**, and write the stable CLAUDE.md edits. Briefly confirm what was written to each.
2. **Codebase only** — Draft the commit message and present it as a clean copyable block:
   - Match the project's prefix/scope style exactly (`feat(v5.x):`, `fix(I03):`, `chore:` …).
   - Subject: imperative, ≤72 chars.
   - Body (only if complex): 2–3 bullets, ≤80 chars each.
   - No `Co-Authored-By` unless the user asks.
3. **Codebase only** — Say: *"Copy that and run `git add <files> && git commit -m \"...\"` when ready. Done."* **Notes-based** — Say: *"Done."* (no git instructions — there's nothing to stage or commit).
4. Say: *"Checkpoint written — safe to `/clear`; re-anchor next session from `<re-anchor target>`."* Pick the re-anchor target by priority: **`STATUS.md` if it exists** (the live working tier — best re-entry point), else the wiki session-note path, else `CLAUDE.md`. Skip this line only if Stage 0 was skipped (no wiki) and neither STATUS.md nor CLAUDE.md was touched — there's nothing to re-anchor from.

If the user flags changes instead of confirming: revise and re-present the summary. Only write CLAUDE.md on explicit confirmation.

Do not stage files. Do not run any git commands.

---

## Tone and pacing

- Keep it brief — the user is wrapping up.
- The one gate is a single sentence, not a menu.
- If the user says "skip" or "next", respect it and move on.
- If context is compacted, work from the git diff + CLAUDE.md — but still read the diffs; never fall back to memory for the change list.
