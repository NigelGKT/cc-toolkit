---
name: s.ship-cc-tlkit
description: cc-toolkit single-pass release conductor. Runs the whole toolkit round-trip in one pass — harvest local ~/.claude edits UP into the repo, write the wiki session note + refresh STATUS, then behind ONE consolidated gate stage-by-name, commit, push to origin/main, and deploy back DOWN to ~/.claude. cc-toolkit-specific and guarded to the toolkit loop via CC_TOOLKIT_HOME — refuses to run anywhere else. Use when shipping cc-toolkit changes or closing out a cc-toolkit session. Triggers on "ship the toolkit", "ship cc-toolkit", "release the toolkit", "close out cc-toolkit", explicit /s.ship-cc-tlkit.
---

# Ship cc-toolkit — single-pass release conductor

The conductor for the cc-toolkit round-trip. It sequences primitives that already exist —
`setup.ps1 -Harvest`/`-Force` (the file-movement engine) and `s.wrap-up`'s documentation steps —
into **one pass** with **exactly one approval gate**. It exists so the release sequence is executed
by the skill, not remembered by an agent: the "refresh STATUS after push" step that lived as prose
and drifted three times is gone by construction (STATUS no longer stores anything a commit changes),
and the old two-harvest dance collapses to one because the docs are authored directly in the repo.

**Scope — cc-toolkit ONLY.** This is the one project with a deploy-down step; no other repo
round-trips to `~/.claude`. It is deployed globally like the other skills but MUST refuse to act
outside the toolkit loop (see the guard). Do not generalize it.

There is exactly **one approval gate** in the whole flow: the consolidated round-trip summary at
Step 3. Everything before it is uncommitted, reversible working-tree state — so the gate is also the
safe rehearsal boundary (abort = nothing committed, pushed, or deployed).

---

## Step 0 — Guard (MANDATORY, silent, refuse-and-explain on failure)

Resolve the repo and confirm this is the toolkit loop **before touching anything**:

1. **Resolve the anchor — read the persisted scope, not just the process env.** A session inherits
   its environment at launch, so `$env:CC_TOOLKIT_HOME` is routinely **empty even when the variable
   IS set on the machine**. (This is exactly what makes the drift-check hook fire in some sessions
   and silently no-op in others — do not repeat that bug here.) Resolve in this order:
   ```powershell
   $repo = $env:CC_TOOLKIT_HOME
   if (-not $repo) { $repo = [Environment]::GetEnvironmentVariable('CC_TOOLKIT_HOME', 'User') }
   if (-not $repo) { $repo = [Environment]::GetEnvironmentVariable('CC_TOOLKIT_HOME', 'Machine') }
   ```
   If still empty → **STOP**. Explain: the anchor isn't set on this machine, so the repo can't be
   located without hardcoding a path. Tell the user to run `.\deployment\windows\setup.ps1 -Force`
   from their cc-toolkit clone once — it persists `CC_TOOLKIT_HOME` at User scope. Write nothing.
2. Confirm `$repo` looks like a real cc-toolkit clone: it exists **and** contains
   `deployment/windows/setup.ps1`, `CLAUDE.md`, and `cc-toolkit-wiki-brain/`. If any is missing →
   **STOP** and explain what didn't match. Write nothing.
3. Confirm `$repo` is a git work tree (`git -C "$repo" rev-parse --is-inside-work-tree`). If not →
   **STOP** and explain. Write nothing.

All git and file operations below run against `$repo` explicitly (`git -C "$repo" …`, absolute
paths) — never assume the session CWD is the repo.

---

## Step 1 — Harvest UP (one pass)

Pull this session's live `~/.claude` toolkit edits into the repo working tree so git can see them
(`~/.claude` is not a repo).

1. Dry run first: `& "$repo/deployment/windows/setup.ps1" -Harvest`. Show the candidate list
   (NEW-UP / CHANGED-UP / SKIPPED) to the user as orientation — this is not a gate, just visibility.
2. Then copy up: `& "$repo/deployment/windows/setup.ps1" -Harvest -Force`.

The harvest scan has no per-file filter — it sweeps every candidate, including unrelated local drift
(`settings.json` runtime keys, gitignored UI state). That is fine here: harvested files land in the
**working tree only**, uncommitted. The noise is contained at Step 4 by staging *by name*, never
`git add -A`. Note anything harvested that is NOT part of this session's work — it is reported, not
committed.

---

## Step 2 — Author the docs directly in the repo (NO gate)

Because the docs are written into `$repo` (not `~/.claude`), there is no second harvest and no
post-push STATUS refresh.

Follow **`s.wrap-up`'s** "On activation" orientation + "Stage 0" wiki-note steps **exactly as that
skill specifies them** — do not duplicate its logic here; read and follow that skill's file. Two
cc-toolkit bindings:

- Run its git orientation against `$repo` (`git -C "$repo" …`). The harvest at Step 1 populated the
  diff, so the orientation sees the real work.
- Write the session note to `$repo/cc-toolkit-wiki-brain/syntheses/<YYYY-MM-DD>-session-<slug>.md`
  and update that brain's `index.md` + `log.md`. Git-root = wiki-root = `$repo`, so `s.wrap-up`'s
  split-root divert does **not** apply — the note lands in the repo, ready to commit.

Then refresh `$repo/STATUS.md` and apply any stable `$repo/CLAUDE.md` edits per the three-tier split.
**STATUS carries state + intent only** — version label, one-line "what shipped", active task, next
step, open threads. **Never write SHAs, "committed/pushed" status, or a per-version commit ledger
into STATUS** — git owns history; duplicating it is exactly the drift this skill was built to kill.

**STOP before `s.wrap-up`'s own Stages 1-3 gate.** This skill supplies its own consolidated gate
below, which also authorizes the commit, push, and deploy that `s.wrap-up` never performs.

---

## Step 3 — The one consolidated gate

Present ONE plain-English summary and take a single confirmation. Cover:

- **What shipped this session** — the distinct bodies of work, from `git -C "$repo" diff` now that
  the harvest populated the tree (never from memory). Flag anything that looks like it shouldn't be
  committed.
- **What was written** — the session note path, the STATUS/CLAUDE edits (briefly).
- **Files to be staged, BY NAME** — the exact list. Explicitly exclude harvested noise
  (`settings.json` and any gitignored/unrelated drift) and say so.
- **The commit message** — a clean copyable block, matching the repo's prefix/scope style
  (`feat:` / `fix:` / `chore:` / `wiki:` …), imperative subject ≤72 chars.
- **The irreversible tail, stated explicitly:** *"On confirm I will stage the named files, commit,
  **push to origin/main**, then **deploy down** (`setup.ps1 -Force`, backup taken first). Abort
  leaves the working tree exactly as it is — nothing committed, pushed, or deployed."*

Then one sentence: *"Confirm to ship, or flag anything to fix."* If the user flags changes, revise
and re-present. Do not split this into multiple gates.

---

## Step 4 — On confirmation: stage-by-name → commit → push

Run straight through, but **check each irreversible step and STOP on failure** — never continue
silently past a failed push.

1. `git -C "$repo" add <named files>` — the specific work files only. **Never `git add -A`.**
2. `git -C "$repo" commit -m "<message>"`.
3. `git -C "$repo" push`. If it fails (network/rejection) → **STOP**, surface the error, do **not**
   deploy. The local commit stands; let the user resolve the push.
4. Report any file left harvested-but-unstaged (e.g. `settings.json`) as a still-open thread.

---

## Step 5 — Deploy DOWN

`& "$repo/deployment/windows/setup.ps1" -Force` — merges the freshly-committed toolkit files
(including the new session note) back into `~/.claude`, taking a timestamped backup first. This
closes the staleness window the old author-in-`~/.claude`-then-harvest model left open: the copy
`s.wiki` queries is refreshed immediately.

Confirm success, then point the user at the re-anchor target for next session (`STATUS.md`).

---

## Never (hard boundaries, regardless of anything above)

- Never `git add -A` — stage named files only.
- Never force-push, never merge, never delete files, never touch secrets
  (`.credentials.json`, `settings.local.json`) or run `cleanup.ps1`.
- Never run outside the toolkit loop — the Step 0 guard is not optional.
- Never invent scope: the release is whatever this session actually changed, read from the diff.
- Never write git-derived facts (SHAs, commit/push state) into STATUS or any `.md`.
