# GKT cc-toolkit

Machine-agnostic Claude Code configuration — the single source of truth for my
`~/.claude` setup. Clone this on any machine and deploy it in a few minutes so the
same identity, skills, and working style follow me everywhere.

## What's inside

```
cc-toolkit/
├── CLAUDE.md          ← global operating contract (the "Mr Nigel" identity/working style)
├── settings.json      ← global Claude Code preferences
├── skills/            ← custom skills
│   ├── s.wiki/        ← Obsidian-compatible knowledge wiki (source/entity/concept/synthesis)
│   └── s.wrap-up/     ← end-of-session ritual (summarise + promote generalizable lessons)
├── statusline.js      ← status line (context %/model/cwd/branch); backs settings.json statusLine
├── drift-check.ps1    ← SessionStart hook target: warns when local ~/.claude drifts from the repo
├── plugins.json       ← declarative plugin manifest (marketplaces + plugin names; see below)
├── playbooks/         ← client-agnostic lessons distilled from real project work
└── deployment/
    └── windows/
        └── setup.ps1  ← audit / deploy / harvest / check installer (see below)
```

The repo is **flat by design**: each top-level item maps 1:1 to a file/folder inside
`~/.claude`. `setup.ps1` copies exactly these items (`CLAUDE.md`, `settings.json`,
`skills`, `cc-toolkit-wiki-brain`, `statusline.js`, `drift-check.ps1`) — nothing else.

**Plugins are the one exception to "copy".** `~/.claude/plugins/` is runtime state
(self-updating, machine-specific paths) and stays gitignored — so instead of copying the
folder, `plugins.json` records the *intent* (which marketplaces, which plugins) and
`setup.ps1` re-installs them on deploy via the `claude plugin` CLI. You version the
lockfile, not the installed bytes.

## What is NEVER in this repo

Secrets and machine-local state stay off GitHub, always:

- `.credentials.json` — your auth secret
- `settings.local.json` — per-machine overrides
- runtime junk (cache, history, sessions, the `plugins/` folder, plans) — see `.gitignore`.
  Plugins still travel, but as intent in `plugins.json`, not as the installed folder.
- your **API key** — lives in your password manager, set as an env var at deploy time

`setup.ps1` will never deploy or overwrite a secret, and warns loudly if one ever
ends up in the repo by mistake.

## Deploy to a machine (Windows)

```powershell
git clone git@github.com:NigelGKT/cc-toolkit.git
cd cc-toolkit
Set-ExecutionPolicy Bypass -Scope Process   # one-time, this session only
.\deployment\windows\setup.ps1
```

What happens depends on the machine:

- **Clean machine** (no existing Claude Code config) → the toolkit deploys straight away.
- **Existing config detected** → `setup.ps1` runs in **AUDIT MODE** and changes nothing.
  It prints, split by **which side is ahead** (direction is a mtime hint; the content-hash
  decides *whether* files differ):
  - **In sync** — files already identical.
  - **LOCAL NEWER** — edited on this machine, newer than the repo → harvest UP.
  - **HARVEST CANDIDATES** — files (and plugins) on this machine but *not* in the repo → harvest UP.
    Pull anything worth keeping into cc-toolkit (commit + push) so you don't lose local work.
    For files that's `-Harvest` (see below); for a plugin it's `-HarvestPlugins`.
  - **REPO NEWER** — the repo differs and is newer → deploy DOWN with `-Force`.
  - **WOULD BE ADDED / WOULD BE INSTALLED** — new files, and plugins from `plugins.json`
    not yet installed here → deploy DOWN.

  Once you've reviewed and harvested, deploy over the existing config with:

  ```powershell
  .\deployment\windows\setup.ps1 -Force
  ```

  `-Force` takes a lightweight backup of the toolkit files to
  `~/.claude.backup-<timestamp>` first, then merge-copies the toolkit in and hydrates the
  plugins listed in `plugins.json` (`claude plugin marketplace add` + `install` — idempotent).

## Plugins — install locally, harvest up

Install a plugin on this machine however you like (e.g. `claude plugin marketplace add
kepano/obsidian-skills` then `claude plugin install obsidian@obsidian-skills`). To make it
follow you everywhere, record its *intent* into the manifest and push:

```powershell
.\deployment\windows\setup.ps1 -HarvestPlugins   # regenerates plugins.json from installed plugins
git add plugins.json && git commit -m "harvest: <plugin>" && git push
```

On the next `setup.ps1 -Force` (any machine) the plugin re-installs automatically. The
`~/.claude/plugins/` folder itself is never committed — only `plugins.json`.

## Files — edit locally, harvest up

The natural workflow is to build a skill / tweak `CLAUDE.md` / grow the brain **locally in
`~/.claude` first**, then pull it UP into the repo. `-Harvest` is the file-level inverse of
deploy — the counterpart to `-HarvestPlugins`:

```powershell
.\deployment\windows\setup.ps1 -Harvest          # dry-run: lists local files not yet in the repo
.\deployment\windows\setup.ps1 -Harvest -Force   # copies them UP into the repo working tree
git add -A && git commit -m "harvest: <what>" && git push
```

It lists **NEW-UP** (here, not in the repo) and **CHANGED-UP** (edited here, newer than the
repo), copies them into the repo on `-Force`, and **skips** any file where the repo is newer
(that's a deploy-DOWN, not a harvest). Secrets are never harvested.

## Stay in sync automatically — the drift reminder

A **SessionStart hook** (in `settings.json`) runs `setup.ps1 -Check` once per day and prints a
one-line nudge when local toolkit files haven't been harvested yet:

```
cc-toolkit: 2 local file(s) not yet harvested -> run: setup.ps1 -Harvest
```

Because the hook config is synced but a repo *path* can't be, each machine opts in once by
pointing `CC_TOOLKIT_HOME` at its clone. Until it's set, the hook no-ops silently.

```powershell
# one-time per machine (persists across sessions):
[Environment]::SetEnvironmentVariable('CC_TOOLKIT_HOME', 'C:\path\to\cc-toolkit', 'User')
```

The check is read-only, throttled to once/day (a `~/.claude/.toolkit-drift-check` marker), and
never blocks or slows a normal session start.

## After deploy — start working

```powershell
$env:ANTHROPIC_API_KEY = "sk-ant-..."   # retrieve from your password manager
claude
```

Confirm your global context loads (the "Mr Nigel —" canary should appear) and your
skills are available.

## How the toolkit grows

The `s.wrap-up` ritual flags anything generalizable at the end of a session
("Part C — promote"): a reusable skill, a global CLAUDE.md rule, or a client-agnostic
lesson. Those land back here (`skills/`, `CLAUDE.md`, `playbooks/`), get committed, and
ride to every machine on the next deploy. The toolkit compounds over time.

See `CHANGELOG.md` for version history.
