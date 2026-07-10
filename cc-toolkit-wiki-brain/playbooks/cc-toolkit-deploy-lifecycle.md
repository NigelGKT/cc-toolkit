---
type: playbook
tags: [deploy, lifecycle, runbook, cc-toolkit, meta]
origin: GKT cc-toolkit (toolkit deploy + cleanup lifecycle, 2026)
updated: 2026-07-10
status: stable
---

# cc-toolkit Deploy Lifecycle

The end-to-end runbook for the toolkit itself: how to stand it up on any machine, work,
grow the brain, and hand a machine back clean. **Fetch this before running setup** — it is
the canonical flow, so you never have to re-infer the steps.

One-line mental model: **GitHub is the source of truth; every machine deploys *from* it,
never the other way round.** Curate in the repo clone → commit → push → deploy.

## Flowchart

```mermaid
flowchart TD
    subgraph SPINUP["1 - Spin up (any machine, ~5 min)"]
        A["git clone cc-toolkit"] --> B["setup  (audit only, changes nothing)"]
        B --> C{"existing ~/.claude config?"}
        C -- "clean machine" --> F["deploys straight away"]
        C -- "existing config" --> D["review: HARVEST candidates (files + plugins) + CONFLICTS"]
        D --> E["setup -Force  (backup, merge-deploy, hydrate plugins.json)"]
        F --> G["set ANTHROPIC_API_KEY -> claude"]
        E --> G
        G --> H(["canary 'Mr Nigel --' + skills + brain + plugins loaded"])
    end

    subgraph WORK["2 - Work & compound"]
        H --> W["work the engagement"]
        W --> P["s.wrap-up Part C flags a transferable concept/lesson"]
        P --> Q["promote into cc-toolkit-wiki-brain: scrub, set origin:, re-link"]
        Q --> R["commit + push (repo = source of truth)"]
        W --> PL["install a plugin locally (claude plugin install)"]
        PL --> PH["setup -HarvestPlugins  -> regenerates plugins.json"]
        PH --> R
        R --> S["redeploy: setup -Force  (brain + plugins ride to every machine)"]
        S -.->|next session, any machine| H
    end

    subgraph EXIT["3 - Clean exit (client hand-back)"]
        W --> X["cleanup.ps1  (dry run - reports only)"]
        X --> Y{{"GATED: interactive TTY + type hostname; agent blocked by deny rule"}}
        Y --> Z["cleanup.ps1 -Force [-NoBackup]  -> ~/.claude removed"]
    end

    subgraph VPS["4 - Always-on (parked, one sitting)"]
        V1["provision droplet (DO, SGP1, Ubuntu)"] --> V2["setup.sh (auto-installs Node/Claude, deploys)"]
        V2 --> V3["tmux + claude -> /rc pairs phone"]
    end
```

## Runbook — Spin up (Windows-first)

```powershell
# 1. Clone the source of truth
git clone https://github.com/NigelGKT/cc-toolkit.git
cd cc-toolkit

# 2. AUDIT (read-only). On an existing config it prints CONFLICTS / HARVEST / WOULD-ADD
#    and changes nothing. On a clean machine it just deploys.
.\deployment\windows\setup.ps1

# 3. HARVEST first (only if the audit lists HARVEST CANDIDATES): copy anything machine-only
#    UP into the repo, commit, push. Skipping this loses that machine's customizations.

# 4. DEPLOY. Backs up existing toolkit files to ~/.claude.backup-<ts>, then merges
#    (never mirror-deletes; never touches secrets or settings.local.json).
.\deployment\windows\setup.ps1 -Force

# 5. Key + launch
$env:ANTHROPIC_API_KEY = "sk-ant-..."   # from password manager
claude                                   # confirm the "Mr Nigel --" canary
```

Unix / VPS is identical in spirit: `bash deployment/unix/setup.sh` (auto-installs Node via
nvm + Claude via npm), `--force` to deploy.

## Runbook — Grow the brain (the compounding loop)

1. At session end, `s.wrap-up` **Part C** flags a generalizable concept or lesson.
2. Copy it from the project wiki into `cc-toolkit-wiki-brain/` (`concepts/` for a pattern,
   `playbooks/` for a checklist). **Scrub** all client identifiers from the body; record the
   source only in `origin:`. Re-link `[[...]]` and update `index.md`.
3. `git commit && git push` in the repo clone.
4. Redeploy (`setup -Force`) so the new knowledge rides to every machine.

Query the other direction before solving anything cold: *"what does my brain say about X"* →
`s.wiki` against `~/.claude/cc-toolkit-wiki-brain/`.

## Runbook — Harvest a plugin (install local, ride everywhere)

Plugins are the one item that is **hydrated, not copied**. `~/.claude/plugins/` is runtime
state (self-updating, absolute machine paths) and stays gitignored — so we version the
*intent* in `plugins.json` and re-install on deploy.

```powershell
# 1. Install locally however you like
claude plugin marketplace add kepano/obsidian-skills
claude plugin install obsidian@obsidian-skills

# 2. Pull the intent UP into the manifest (strips machine-specific paths/timestamps)
.\deployment\windows\setup.ps1 -HarvestPlugins    # regenerates plugins.json

# 3. Commit + push
git add plugins.json; git commit -m "harvest: obsidian-skills"; git push

# 4. On any machine, the next deploy re-installs it automatically
.\deployment\windows\setup.ps1 -Force             # marketplace add + install (idempotent)
```

The audit (`setup.ps1` on an existing config) lists installed-but-unrecorded plugins as
**HARVEST CANDIDATES (plugins)** and manifest-but-not-installed ones as **WOULD BE
INSTALLED** — the same intent comparison, never a byte diff.

## Runbook — Clean exit (client hand-back)

```powershell
.\deployment\windows\cleanup.ps1                  # dry run - shows what WOULD be removed
.\deployment\windows\cleanup.ps1 -Force           # backs up to ~/.claude.backup-cleanup-<ts>, then removes
.\deployment\windows\cleanup.ps1 -Force -NoBackup # client exit - no residue left behind
```

`-Force` is gated twice so it cannot fire by accident: an assistant is blocked at the tool
boundary (`permissions.deny` in `settings.json`), and the script itself refuses a
non-interactive shell and demands you type the machine's hostname to confirm.

## Why -Force is safe (not destructive) in setup

`setup.ps1 -Force` is a **confirmation gate past the audit stop**, not a wipe. It takes a
timestamped backup first, then *merges* toolkit files in (`Copy-Item -Recurse -Force`) — it
never mirror-deletes and never touches secrets (`.credentials.json`, `settings.local.json`)
or runtime state. Contrast `cleanup.ps1 -Force`, which **is** destructive (removes all of
`~/.claude`) — hence its extra human gate.

## Key invariants (don't violate)

- **Curate in the repo clone, never the deployed `~/.claude/cc-toolkit-wiki-brain/`** — the deployed copy is a
  target, overwritten on every deploy.
- **Secrets never enter the repo** — API key from a password manager; `.credentials.json`
  and `settings.local.json` stay local (the latter is where machine-specific hooks live and
  survives deploys untouched).
- **Deploy contract is folder-name-keyed** — `ToolkitItems = CLAUDE.md, settings.json,
  skills, cc-toolkit-wiki-brain`. Renaming a deployed folder means updating that list in
  `setup.ps1` **and** `setup.sh` in lockstep, or it silently stops deploying.
- **Plugins are hydrated, never copied** — `plugins.json` (marketplaces + plugin names) is
  the source of truth; the `~/.claude/plugins/` folder is gitignored runtime state. Never
  commit the folder; harvest with `-HarvestPlugins`, which strips machine-specific paths.
  (Unix `setup.sh` still needs the parallel port for this to hold on the VPS track.)

## Transfer note

The pattern generalizes to any "config-as-code deployed to disposable machines" setup:
audit-before-write with a harvest step so a target's local drift is pulled up before it's
overwritten; a merge (never mirror) deploy that leaves secrets and local overrides alone;
and a separate, human-gated teardown path kept well away from the everyday deploy path.

## Related
- [[../wiki-schema]] — brain conventions, promote/query/lint flows
- [[README]] — playbooks folder intent
