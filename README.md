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
├── plugins.json       ← declarative plugin manifest (marketplaces + plugin names; see below)
├── playbooks/         ← client-agnostic lessons distilled from real project work
└── deployment/
    └── windows/
        └── setup.ps1  ← audit-or-deploy installer (see below)
```

The repo is **flat by design**: each top-level item maps 1:1 to a file/folder inside
`~/.claude`. `setup.ps1` copies exactly these items (`CLAUDE.md`, `settings.json`,
`skills`, `cc-toolkit-wiki-brain`) — nothing else.

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
  It prints:
  - **In sync** — files already identical.
  - **CONFLICTS** — files that differ (review which version should win).
  - **HARVEST CANDIDATES** — files (and plugins) on this machine but *not* in the repo.
    Pull anything worth keeping UP into cc-toolkit first (commit + push) so you don't lose
    local work. For a plugin, "pull up" is one command — see below.
  - **WOULD BE ADDED / WOULD BE INSTALLED** — new files, and plugins from `plugins.json`
    not yet installed here.

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
