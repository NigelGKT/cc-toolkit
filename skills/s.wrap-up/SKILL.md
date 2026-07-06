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

1. `git log --oneline -20` — learn the commit message style (prefix/scope, version numbering) and recent history shape.
2. **Capture everything unpushed — this is the authoritative source of truth. NEVER summarise from in-session memory.**
   - `git status` — staged, unstaged, untracked.
   - `git log --oneline @{u}..HEAD` — local commits not on the remote (fallback `HEAD~5..HEAD` if no upstream).
   - `git diff --stat @{u}` — every changed file with line counts (fallback `git diff --stat HEAD`).
   - **For every non-trivial file in that stat, READ its actual diff** (`git diff @{u} -- <file>`), not just the stat line. A large diff in a single file routinely bundles **multiple unrelated bodies of work** from parallel sessions — you will miss them if you only read the files you personally touched this session.
3. Read `CLAUDE.md` in CWD fully if present — note version, backlog, versioning convention.
4. Check for a wiki: probe `./wiki-schema.md` or scan `CLAUDE.md` for a `## Wiki` section pointing to a subfolder.

**THOROUGHNESS SELF-CHECK — answer these explicitly before moving on:**
- Did I read every non-trivial diff, or only the changes I remember making this session?
- Does any single file's diff contain several *distinct* changes (a feature + a refactor + a rename) that I'd otherwise lump into one vague line? List each separately.
- Are any untracked files/folders real work (docs, plans, notes) rather than runtime data?
- Enumerate the **distinct bodies of work** as a list. If that list came from memory rather than the diffs, STOP and re-read the diffs.
- Did anything this session **generalize beyond this project** — a reusable command/skill, a global CLAUDE.md rule, or a client-agnostic lesson? Note it for the promote step (Part C).

This self-check is the fix for the single most common failure of this skill: under-reporting because the summary was written from memory instead of the diff.

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

**A — What changed since the last push.** The distinct bodies of work from the self-check (each as its own bullet, even when several live in one file), which files they touch, and how many unpushed commits exist. Flag anything that looks like it shouldn't be committed (`.env`, large binaries, temp files), and anything reverted.

**B — What I'll change in CLAUDE.md.** The surgical edits: version bump (follow project convention), backlog status, architecture/data-flow notes, key-files table, config section. Be explicit about what you are **not** touching. Do not infer changes that aren't in the diff.

**C — Promote to the global toolkit (cc-toolkit)?** Anything from this session that generalizes beyond this project: a reusable command → `commands/`, a skill → `skills/`, a refined global behaviour → global `CLAUDE.md`, a **transferable pattern/concept → `brain/concepts/`**, or a **client-agnostic lesson/checklist → `brain/playbooks/`**. List each as a one-line candidate with its target. For anything going into `brain/`, note that promotion means **scrub project specifics from the body and record the source in `origin:` frontmatter** (see `brain/wiki-schema.md`). **Flag-only:** never auto-push to cc-toolkit and never add a gate for it — the user promotes manually. If nothing generalizes, say "nothing to promote" and move on.

Then ONE gate, one sentence: *"Confirm to apply, or flag anything to fix."*

### On confirmation

Run straight through — no further gates:
1. Write the CLAUDE.md changes. Briefly confirm what was written.
2. Draft the commit message and present it as a clean copyable block:
   - Match the project's prefix/scope style exactly (`feat(v5.x):`, `fix(I03):`, `chore:` …).
   - Subject: imperative, ≤72 chars.
   - Body (only if complex): 2–3 bullets, ≤80 chars each.
   - No `Co-Authored-By` unless the user asks.
3. Say: *"Copy that and run `git add <files> && git commit -m \"...\"` when ready. Done."*

If the user flags changes instead of confirming: revise and re-present the summary. Only write CLAUDE.md on explicit confirmation.

Do not stage files. Do not run any git commands.

---

## Tone and pacing

- Keep it brief — the user is wrapping up.
- The one gate is a single sentence, not a menu.
- If the user says "skip" or "next", respect it and move on.
- If context is compacted, work from the git diff + CLAUDE.md — but still read the diffs; never fall back to memory for the change list.
