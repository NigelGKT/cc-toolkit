---
type: synthesis
tags: [session-note]
sources: []
updated: 2026-07-10
status: stable
query: "Session note — cc-toolkit plugin harvest + hydrate"
---

# Session Note — 2026-07-10 — Plugin Harvest + Hydrate

## What was attempted
Make Claude Code plugins (starting with `kepano/obsidian-skills`) travel with cc-toolkit the
same way skills do — *install locally -> harvest up -> redeploy everywhere* — **without**
committing the volatile, self-updating `~/.claude/plugins/` folder.

## What shipped
- **`plugins.json`** (new) — declarative manifest: `{ marketplaces: name->repo, plugins: [name@marketplace] }`; seeded with `obsidian@obsidian-skills` / `kepano/obsidian-skills`.
- **`setup.ps1`** — `-HarvestPlugins` switch (regenerates the manifest from live machine state, stripping absolute paths / timestamps / SHAs); audit now reports **HARVEST CANDIDATES (plugins)** and **WOULD BE INSTALLED**; deploy hydrates via `claude plugin marketplace add` + `install --scope user` (idempotent; tolerant of offline / missing `claude`).
- **Docs** — `README.md` ("Plugins — install locally, harvest up"), deploy-lifecycle playbook (mermaid + plugin runbook + invariant), `CHANGELOG.md` v1.8.0.
- Committed + pushed to `origin/main` as `baeb407`.

## What was deferred
- **Unix `setup.sh` port** — plugin layer is Windows-only; the VPS track needs the parallel port (flagged in CHANGELOG + playbook invariant).
- **Version pinning** — installs latest by design; per-version pinning available later if reproducible builds are ever needed.

## Open threads
- Pattern promoted this session: [[../concepts/declarative-intent-over-materialized-state]] — the reusable idea behind the design.
