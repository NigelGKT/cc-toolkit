---
type: harness
tags: [hooks, permissions, settings, statusline, settings-local]
origin: GKT cc-toolkit (harness process mapping, 2026)
updated: 2026-07-18
status: stable
---

# Hooks, Permissions, and the Statusline

The rest of `settings.json`'s surface beyond what [[harness-overview]] covers in passing:
how hooks actually fire, why two settings files exist, what the permission allow/deny lists
do, and what data drives the statusline.

## Two settings files, one split

| File | Deployed? | Holds |
|---|---|---|
| `settings.json` | Yes — `cc-toolkit`'s source of truth, redeployed on every `-Force` | Shared config: permission allow/deny lists, `model`/`effortLevel` defaults, the `SessionStart` hook, `statusLine`, plugin runtime keys |
| `settings.local.json` | **Never** — gitignored, machine-local only | Secrets, and hooks/config that should NOT ride to every machine (currently: `PostToolUse` + `Stop` dashboard-logging hooks) |

`setup.ps1`'s `$NeverTouch` list hard-codes `settings.local.json` (alongside
`.credentials.json`) as something deploy and harvest must never read or write — see
[[../playbooks/cc-toolkit-deploy-lifecycle]]. `model` and `effortLevel` inside `settings.json`
are a related but distinct case: they *are* deployed, but excluded from the drift *comparison*
(`$SettingsRuntimeKeys`) because `/model` and the effort toggle rewrite them locally every
session — see the 2026-07-18 session note for the fix.

## Hook mechanics

A hook entry is keyed by event name, with a `matcher` (glob-like filter over tool names —
`"*"` matches every call) and a list of `{ type: "command", command: "..." }` actions. The
command receives the event as JSON on **stdin** and can inspect/act on it; nothing here
requires a specific language — this toolkit mixes PowerShell and inline Node.

Configured today:

- **`SessionStart`** (`settings.json`, shared) → `drift-check.ps1`. Resolves `CC_TOOLKIT_HOME`
  from the *persisted* scope (not just `$env:`, which is empty in any session that didn't
  inherit it — see [[../incidents/2026-07-16-self-description-drift]]), then delegates to
  `setup.ps1 -Check`: a silent, once-per-24h, side-effect-free drift verdict. Wrapped so any
  internal error is swallowed — a hook must never break session start.
- **`PostToolUse`** (`settings.local.json`, machine-local, matcher `"*"`) → reads the event
  JSON off stdin and appends one line (`{type, tool, sessionId, timestamp}`) to
  `~/.claude/.dashboard-events.jsonl`.
- **`Stop`** (`settings.local.json`, machine-local) → the same append, fired when a turn ends.

Both dashboard hooks live in the *local* file, not the deployed one — telemetry logging is a
per-machine concern, not shared toolkit behavior, so it never rides to another machine via
deploy.

## The permission model

`settings.json`'s `permissions` block has two lists, matched against `Bash(...)` /
`PowerShell(...)` command patterns:

- **`allow`** — auto-approved without prompting. Everything currently listed is read-only
  inspection: `git status/log/diff/show/branch/remote -v/worktree list`, `ls`, `dir`, `wc`,
  `head`, `tail`, `du`, `date`, version checks (`node --version`, `python --version`), and the
  PowerShell equivalents (`Get-ChildItem`, `Get-Content`, `Get-Command`, `Test-Path`,
  `Get-CimInstance`, plus the same three `git` read commands). Nothing that mutates state is
  on this list.
- **`deny`** — refused outright, in both Bash and PowerShell form: any invocation matching
  `*cleanup.ps1*` or `*cleanup.sh*`. This is the tool-level enforcement of the same rule
  `s.ship-cc-tlkit` states in prose ("never run `cleanup.ps1`") — belt-and-suspenders, not
  redundant, since a hard deny holds even if a future skill's prose boundary is missed.
- **Anything not on either list** falls through to the harness's normal interactive
  permission prompt for the session's chosen permission mode.

## The statusline

`statusLine.command` runs `node ~/.claude/statusline.js` on each render, fed a JSON payload
on stdin. It prints up to four lines:

1. **Folder + repo** — cwd basename, plus a clickable `owner/repo` link when the workspace has
   a git remote.
2. **Model + effort + context + cost** — model display name; effort level if set; context-
   window used%, colour-coded (green `<70`, yellow `70–89`, red `≥90`); session cost; elapsed
   duration; lines added/removed if any.
3. **`[session]` bar** — 5-hour rate-limit usage, once the first API response of the session
   has populated it.
4. **`[week]` bar** — 7-day rate-limit usage, Claude.ai-subscriber accounts only.

Lines 3–4 are conditionally absent (no data yet, or not applicable to the account) rather
than rendered empty.

## Related
- [[harness-overview]] — anchor note; the "pieces, briefly" section this page expands on
- [[session-lifecycle]] — what a session does under this permission/hook surface
- [[../incidents/2026-07-16-self-description-drift]] — the `CC_TOOLKIT_HOME` env-vs-persisted-scope failure the `SessionStart` hook had to be fixed for
- [[../playbooks/cc-toolkit-deploy-lifecycle]] — what deploy/harvest do and don't touch (`$NeverTouch`, `$SettingsRuntimeKeys`)
