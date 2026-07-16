# Changelog

All notable changes to the GKT cc-toolkit. Versioning is `major.minor`.

## [1.18.0] — 2026-07-17

Ship the **Bootstrap self-guard** for `/s.wiki` — the highest-leverage unshipped response to the
2026-07-16 self-description-drift incident (open question 2). Detection was hardened in v1.16.0
(subfolder-glob probe + scope-gated pointer), but that only lowers the odds of a *wrong verdict*;
Bootstrap still trusted the verdict and would scaffold `index.md`, `log.md`, and folders into
whatever `WIKI_ROOT` resolved to. This adds an **independent** guard that inspects the target on
disk and refuses to write into a populated one — so a wrong probe degrades from "silently clobbered
a repo" to "asked a question."

### Changed
- **`s.wiki` Bootstrap — new mandatory Step 0 safety gate.** Before any scaffold, evaluate the
  *final* `WIKI_ROOT`: **safe** if it does not exist or is empty; **unsafe** (STOP, write nothing)
  if it is non-empty — especially if it holds a `.git/` (repo root), a `CLAUDE.md` (project root),
  or any file Bootstrap did not create. On unsafe, ask once (scaffold-a-subfolder / override /
  abort) and proceed only on explicit choice. Re-checked at Step 2 against the final path in case
  the interview changed it.
- **`s.wiki` probe warning** now names the Step 0 gate as the independent backstop — step (c)
  lowers the chance of a wrong verdict; the gate makes a wrong verdict harmless.

### Note
- Guard verified by **simulation against scratch fixtures** (nonexistent / empty / populated-repo /
  populated-plain) — the incident's own footgun scenario (`.git` + `CLAUDE.md`) now halts and asks.
  A true end-to-end `/s.wiki` run needs a session restart to reload the skill; deferred to the operator.
- **Scope: `s.wiki` only.** `s.wrap-up`'s mirror failure (a wrong probe *silently skips* the session
  note rather than scaffolding) is a different shape and deliberately left for later — its fix is
  visibility (surface the skip), not a write-guard.

## [1.17.0] — 2026-07-16

Add an **`incidents/` zone** to the global brain and capture the session's first incident.
Motivated by three self-description failures surfacing in one session (a stale invariant, blind
wiki probes, and a structurally-stale `STATUS.md`) that had one thing in common: nothing in the
toolkit could detect any of them. The brain has content-hash drift detection for *files* and
nothing for semantic drift between what its documents *claim* and what its code *does*.

### Added
- **`cc-toolkit-wiki-brain/incidents/`** — a zone for failure analyses, kept separate from
  `harness/` so an open question is never mistaken for settled documentation. New `incident` page
  type with its own lifecycle vocabulary (`open` / `analyzed` / `resolved`), registered in
  `wiki-schema.md`; graph colour group 🔴 `path:incidents/`; `incidents/README.md` charter.
- **`incidents/2026-07-16-self-description-drift.md`** (`status: open`) — the capture. Classifies
  the three failures as distinct (staleness / migration gap / structural), records the
  agent-behaviour layer (procedure trusted over evidence), and parks seven open design questions.
  Highest-leverage unshipped candidate: a Bootstrap self-guard that refuses to scaffold into a
  populated folder — which would make the wiki-detection footgun harmless regardless of probe
  correctness.

### Note
- The incident's Failure 3 (structurally-stale `STATUS.md`) **recurred a third time closing out
  this very version** — `ec8fb35` was committed as `v1.17.0` without its CHANGELOG entry or a
  `STATUS.md` refresh, exactly the drift the new close-out step 6 was written to prevent. Step 6
  is unenforced prose, so it did not fire. Recorded in the incident as live evidence for open
  questions 5 and 7 (rituals whose artifacts are false at rest; prose guardrails have no teeth).

## [1.16.0] — 2026-07-16

Fix a **live footgun**: `/s.wiki` invoked from the cc-toolkit repo root would fail to detect the
existing `cc-toolkit-wiki-brain/` and run **Bootstrap**, scaffolding a fresh vault (`index.md`,
`log.md`, folders) over the repo root. Both detection probes missed it — the brain is a
subfolder, not at CWD root, and cc-toolkit's `CLAUDE.md` **is** the global operating contract,
so it carried no project-local `## Wiki` pointer. The same blind spot made `s.wrap-up` silently
skip its session note (caught in the act this session).

### Added
- **`## Wiki` section in the global `CLAUDE.md`** — scope-gated: it applies **only** when CWD is
  one of the contract's own two homes (the `cc-toolkit` repo clone or its deploy target
  `~/.claude`), where the relative path `./cc-toolkit-wiki-brain/` happens to be identical. The
  scope gate is load-bearing — this file is injected into every session regardless of CWD, so an
  ungated pointer would imply a wiki path that's false for every other project.

### Changed
- **`s.wiki` probe** — now falls through to a one-level glob for `*/wiki-schema.md` before
  concluding a wiki is absent (one match wins; several → ask). Bootstrap is destructive-by-surprise
  when the probe is wrong, so the fallback is the guard.
- **`s.wrap-up` probe** — same subfolder-glob fallback, plus an explicit **split-root** rule: the
  git repo and the wiki brain need not share a root (here git orientation runs against the clone
  while the session note is written to the `~/.claude` authoring copy).
- **`playbooks/cc-toolkit-deploy-lifecycle.md`** — new **session close-out runbook**: the canonical
  work → harvest → wrap-up → harvest → commit order, why two harvests are load-bearing (wrap-up
  must *read* the work through git, which only sees the repo; and it *writes* the note into
  `~/.claude`, which must then be synced), and the `git add -A` staging trap.

## [1.15.0] — 2026-07-16

Give the global brain a **dual charter**: transferable patterns (existing) plus a new
`harness/` zone for self-documentation of the Claude Code toolkit itself, so the meta-level
process knowledge (memory routing, deploy/harvest mechanics, skills) has a proper home instead
of squatting in the transferable-patterns space or staying purely tacit.

### Added
- **`cc-toolkit-wiki-brain/harness/`** — 4 notes: `harness-overview` (anchor meta-map, with
  flowchart), `memory-architecture` (the two memory systems — harness auto-memory vs. the
  three-tier project convention — and the routing rule between them), `skills-catalog`
  (`s.wiki`/`s.wrap-up`/`s.goal-run`/`obsidian@obsidian-skills` triggers + flows), `README`
  (zone charter).
- **`.obsidian/graph.json`** — colour group for `path:harness/` (🔵), inserted above the
  source/raw catch-all per the schema's own ordering rule.

### Changed
- **`wiki-schema.md`** — declares the dual charter; registers the `harness` page type; adds
  two house-style carve-outs (harness pages may name toolkit internals; `## Transfer note` is
  optional, not mandatory, for self-doc). **Amends the curation invariant**: "never edit the
  deployed copy" (written before `-Harvest` existed) → "prefer the repo clone; local editing is
  supported via `-Harvest` — harvest promptly, since an unharvested edit is destroyed by the
  next `-Force` deploy and the drift-check hook is the only guard."
- **`playbooks/cc-toolkit-deploy-lifecycle.md`** — fills gaps the playbook predates: a general
  file-harvest runbook (`-Harvest` for any toolkit item, not just plugins), a drift-check-hook
  runbook (throttling, silent-by-design, the settings.json semantic-compare rationale), and the
  matching invariant amendment. Cross-linked to the new `harness/` notes.

## [1.14.0] — 2026-07-15

Introduce the **three-tier project memory architecture** (`CLAUDE.md` → `STATUS.md` → wiki brain),
split by rate-of-change, and wire the skills to maintain the new working tier. Rolled out across the
workspace's project folders (per-subproject for the `trading-scripts` monorepo).

### Added
- **`## Memory architecture` in the global `CLAUDE.md`** — the canonical three-tier contract
  (stable `CLAUDE.md` / volatile `STATUS.md` / long-term wiki brain) plus the ownership scope split
  (operator facts → harness memory; cross-project knowledge → `cc-toolkit-wiki-brain`; per-project
  domain → that project's brain). Stated once here; project `CLAUDE.md` files carry only thin pointers.
- **`skills/s.wiki/templates/status.md`** — a STATUS.md scaffold for the working tier.
- **`STATUS.md`** (repo-local, not deployed) — cc-toolkit's own repo / config / deploy state.

### Changed
- **`s.wiki` bootstrap (Step 2b)** now scaffolds `STATUS.md` at the project root + a thin `## Memory`
  pointer alongside `## Wiki` (never clobbers an existing STATUS.md), and adds an ingest scope-boundary
  rule (project brains take domain knowledge only; operator/global facts routed elsewhere).
- **`s.wrap-up`** orients on `STATUS.md`, routes volatile state (version / active task / next step)
  there instead of `CLAUDE.md` when it exists, and re-anchors the checkpoint to `STATUS.md`.

## [1.13.0] — 2026-07-15

### Fixed
- **`settings.json` no longer false-positives in the drift check after every deploy.** Plugin
  hydration rewrites the deployed `settings.json` — it appends runtime keys (`enabledPlugins`,
  `extraKnownMarketplaces`) and reorders the whole file — which made `-Check` and the audit flag
  it as LOCAL NEWER on every deploy (alarm fatigue on the reminder shipped in 1.12.0). It's now
  compared **semantically**: canonical JSON that drops the runtime keys (`$SettingsRuntimeKeys`),
  sorts object keys recursively, then hashes. Any real settings change is still detected; a
  non-JSON file falls back to the raw content hash.

## [1.12.0] — 2026-07-15

Systematize the **local → repo harvest** direction (detect + act + remind), closing the
asymmetry where `setup.ps1` only ever pushed the repo DOWN and left pulling local work UP as a
manual, forgettable step.

### Added
- **`setup.ps1 -Harvest`** — the file-level inverse of deploy (counterpart to `-HarvestPlugins`).
  Lists **NEW-UP** (machine-only) + **CHANGED-UP** (edited locally, newer than the repo) toolkit
  files; dry-run by default, `-Force` copies them into the repo working tree. Skips repo-newer
  files (those are deploy-DOWN) and never harvests secrets.
- **`setup.ps1 -Check`** — fast, silent, once-per-day drift verdict for the SessionStart hook.
  Prints a single nudge line when local files aren't harvested yet, else nothing. Throttled via a
  `~/.claude/.toolkit-drift-check` marker; side-effect-free (no installs, no deploy).
- **`drift-check.ps1`** (new deployed item) — the SessionStart hook target. Delegates to
  `setup.ps1 -Check` when `CC_TOOLKIT_HOME` points at a clone; no-ops otherwise. Uses a `-File`
  wrapper (not an inline `-Command`) so it's robust to however the harness shell quotes the hook.
- **`settings.json` SessionStart hook** — `powershell -NoProfile -File ~/.claude/drift-check.ps1`.
  Opt-in per machine via the `CC_TOOLKIT_HOME` env var; silent until set.
- **`Get-ToolkitDrift`** helper — shared classifier (InSync / LocalNewer / RepoNewer / NewLocal /
  NewRepo) used by the audit, `-Harvest`, and `-Check` so all three agree.

### Changed
- **Audit is now direction-aware.** The single `CONFLICTS` bucket is split into **LOCAL NEWER**
  (harvest UP) vs **REPO NEWER** (deploy DOWN) by `LastWriteTime`; content-hash stays authoritative
  for *whether* files differ. "Next steps" text rewritten to name both directions and point to
  `-Harvest`. Direction is labeled a hint (a fresh `git clone` resets mtimes).
- **Header + prerequisite checks are skipped under `-Check`** so the hook is silent and never
  triggers a winget/npm install on session start.
- **Deploy manifest** gains `statusline.js` (already deployed) + `drift-check.ps1` in the
  documented item list.

## [1.11.0] — 2026-07-15

### Added
- **`skills/s.wiki/reference/obsidian-native.md`** — harvested from this machine. Documents
  how `s.wiki` delegates Obsidian-native materialization (Bases, Canvas, callouts, CLI,
  Defuddle) to the `kepano/obsidian-skills` plugin family instead of reimplementing it.

### Changed
- **`skills/s.wrap-up/SKILL.md`** — harvested from this machine's deployed copy, which had
  gained a full **notes-based wrap-up mode** (for non-git projects: walks the session's
  tool-call record instead of a diff) that the repo's copy lacked. The deployed copy was
  edited directly at some point, bypassing the curate-in-repo rule; this pulls it back to
  canonical.
- **`settings.json` `effortLevel`** — `xhigh` → `high`, matching this machine's live setting.

### Notes
- Audit (`setup.ps1`, no `-Force`) also flagged the deploy-lifecycle playbook and
  `.obsidian/workspace.json` as CONFLICTS — both are expected: the playbook was ahead in
  the repo (this session's v1.10 edit not yet redeployed here) and `workspace.json` is
  gitignored Obsidian UI churn. Neither needed harvesting.

## [1.10.0] — 2026-07-11

### Added
- **`setup.sh` plugin parity (closes the Windows/Unix gap from 1.8.0).** The Linux/macOS
  deploy now carries the full declarative plugin layer that `setup.ps1` had:
  `--harvest-plugins` regenerates `plugins.json` from live state, the audit reports plugin
  **HARVEST CANDIDATES** / **WOULD BE INSTALLED**, and `--force` **hydrates** from the
  manifest (`claude plugin marketplace add` + `install --scope user`). Idempotent; tolerant
  of offline / missing `claude`. JSON is parsed with **node** (already a guaranteed
  prerequisite) rather than adding a `jq` dependency a fresh VPS wouldn't have.

### Fixed
- **BOM tolerance in the manifest reader.** `plugins.json` written by `setup.ps1` on Windows
  PowerShell 5.1 (`Set-Content -Encoding UTF8`) carries a UTF-8 BOM, which `JSON.parse`
  rejects. The Unix readers strip a leading BOM (pure-ASCII `charCodeAt` guard) so a manifest
  authored on Windows hydrates correctly on Linux. Caught by a cross-script parity test.

### Notes
- The VPS track's last toolkit-side prerequisite is now cleared — plugins ride to a Linux
  deploy the same as Windows.

## [1.9.0] — 2026-07-11

> Backfilled from commits `768290e` / `8fc3bcc` / `35680ed`, which shipped under this
> version but did not write a CHANGELOG entry.

### Added
- **Status line (`statusline.js`, new).** A two-row status line wired via `settings.json`
  `statusLine`: folder + branch on one row; model, effort, context %, session cost,
  duration, and lines on the other, with rate-limit usage bars (session 5h + weekly) and a
  reset countdown. Added to the deploy manifest (`TOOLKIT_ITEMS`) in both `setup.ps1` and
  `setup.sh` so it rides to every machine.
- **Permission allowlist in `settings.json`.** Read-only and safe-git commands (status/log/
  diff/show/branch, `ls`/`head`/`tail`/`wc`, `--version` probes, etc.) are pre-approved so
  routine inspection doesn't prompt — the cleanup `deny` block still stands above it.

### Changed
- **`CLAUDE.md` operating contract** gained a **scope gate** (an approved plan or explicit
  scope authorizes every edit within it — no per-file re-ask), an **efficiency
  (outcome-per-token)** section, and a **session-lifecycle** section (one task per session;
  checkpoint → `/clear`; re-anchor on resume).
- **`s.wrap-up`** now ends with a `/clear` + re-anchor reminder after drafting the commit.

## [1.8.0] — 2026-07-10

### Added
- **Plugin harvest + hydrate — plugins now ride to every machine, declaratively.** Claude Code
  plugins (e.g. `kepano/obsidian-skills`) live in `~/.claude/plugins/`, which is self-updating,
  machine-path-laden runtime state and stays gitignored — so the toolkit versions the *intent*,
  not the bytes (the npm lockfile pattern: track the manifest, re-install `node_modules`).
  - **`plugins.json`** (new, repo root) — declarative manifest: `{ marketplaces: name→repo,
    plugins: [name@marketplace] }`. Seeded with `obsidian@obsidian-skills`.
  - **`setup.ps1` audit** now reports **HARVEST CANDIDATES (plugins)** — installed here but not
    in `plugins.json` — and **WOULD BE INSTALLED** — in the manifest but not on this machine. An
    intent comparison (reads `~/.claude/plugins/{known_marketplaces,installed_plugins}.json`,
    stripping absolute paths/timestamps/SHAs), never a byte diff.
  - **`setup.ps1 -Force` deploy** now hydrates from the manifest via `claude plugin marketplace
    add` + `claude plugin install --scope user`. Idempotent; tolerant of offline / missing
    `claude` (degrades to printing the commands to run by hand).
  - **`setup.ps1 -HarvestPlugins`** (new switch) — regenerates `plugins.json` from this machine's
    live plugin state, then stops. One-command "pull up" for a locally installed plugin. Keeps
    default marketplaces (`claude-plugins-official`) out unless a listed plugin depends on one.
  - Docs: `README.md` (new "Plugins — install locally, harvest up" section) and the
    deploy-lifecycle playbook (mermaid + plugin runbook + a new invariant) updated to match.

### Notes
- Verified against Claude Code v2.1.197: `claude plugin marketplace add` / `install` are
  non-interactive with real exit codes, so hydration is fully scriptable.
- **Unix `setup.sh` not yet ported** — the plugin layer is Windows-only for now; the VPS track
  needs the parallel port before this holds there (flagged in the playbook invariant).

## [1.7.0] — 2026-07-09

### Added
- **`cc-toolkit-wiki-brain/playbooks/cc-toolkit-deploy-lifecycle.md`** — the toolkit's own
  runbook as the first brain playbook: a Mermaid flowchart of the full lifecycle (spin up →
  work & compound → clean exit → VPS) plus copy-paste command runbooks for each leg, the
  `-Force` safety rationale, and the deploy invariants. Fetch it from the brain before
  running setup instead of re-deriving the flow. `index.md` links it.

## [1.6.0] — 2026-07-09

### Added
- **Cleanup gate — defense in depth against an accidental `cleanup.ps1 -Force`.** The cleanup
  scripts wipe all of `~/.claude` (config, secrets, session history); a mistaken or automated
  invocation had nothing standing in its way. Two independent guards now do:
  - **Layer 1 — harness deny.** `settings.json` gains a `permissions.deny` block matching
    `cleanup.ps1` / `cleanup.sh` under both the Bash and PowerShell tools. An assistant that
    tries to run cleanup is blocked at the tool boundary and the operator gets a permission
    prompt it cannot self-approve. Rides to every machine via deploy.
  - **Layer 2 — in-script human gate.** `-Force` / `--force` now refuses to run when stdin is
    non-interactive (`[Console]::IsInputRedirected` / `! -t 0` — the signature of an automated
    or piped shell) and, when interactive, requires the operator to type the machine's own name
    (`$env:COMPUTERNAME` / `hostname`) to proceed. Either guard failing aborts with zero changes.
    This is the hard guarantee: it holds regardless of caller, and an assistant has no TTY to
    satisfy it.

## [1.5.0] — 2026-07-09

### Changed
- **`brain/` renamed to `cc-toolkit-wiki-brain/`** — clearer, self-describing folder name.
  The deploy contract keys off the folder name, so every path reference was updated in lockstep:
  `setup.ps1` / `setup.sh` (`ToolkitItems`), `wiki-schema.md`, `README.md`, and `s.wrap-up`
  Part C promote targets. Content unchanged — git tracked it as pure renames. Deploys to
  `~/.claude/cc-toolkit-wiki-brain/` from now on.

### Fixed
- **`.gitignore` — Obsidian vault hygiene.** The vault's volatile UI/app state
  (`workspace.json`, `app.json`, `appearance.json`, `core-plugins.json`) was being tracked and
  churning on every session. Now ignored via `**/.obsidian/*`, keeping only `graph.json` (the
  colour-group definitions worth versioning).

## [1.4.0] — 2026-07-08

### Added
- **`skills/s.goal-run/`** — harvested from a machine that had it locally but had never been
  pushed up. Now rides to every machine via deploy.

### Fixed
- **`setup.ps1` / `cleanup.ps1`** — ASCII-cleaned the box-drawing and em-dash characters in the
  output strings so the scripts parse under **Windows PowerShell 5.1**. They were UTF-8 without a
  BOM, which 5.1 reads as the ANSI codepage — corrupting the multi-byte characters and throwing a
  parser error (`Unexpected token '}'`). Many client machines ship only 5.1, so this was a real
  deploy blocker, not cosmetic. Output text only; no logic change.

### Changed
- **Confidentiality decision made** — `origin:` values persist as-is (naming real clients);
  cross-engagement confidentiality is deliberately *not* a concern for the brain. Supersedes the
  deferred note from 1.3.0; recorded in `brain/wiki-schema.md`.
- **Top-level `playbooks/` removed** — superseded by `brain/playbooks/` (was flagged for manual
  deletion in 1.3.0; now done).

## [1.3.0] — 2026-07-06

### Added
- **`brain/`** — the global brain: an `s.wiki` vault of cross-project, distilled patterns and
  client-agnostic lessons, deployed to `~/.claude/brain/` on every machine. Seeded with three
  pattern-concepts (`fifo-vs-vwap-cost-basis`, `convert-at-edge-display-lens`,
  `cost-layer-as-derived-view`) promoted from the Propex PTA wiki — scrubbed to patterns with
  `origin:` provenance in frontmatter. Mirrors PTA's schema + graph colour-group system.
- **`deployment/windows/cleanup.ps1`** + **`deployment/unix/cleanup.sh`** — clean-exit scripts.
  Dry-run by default; `-Force` removes `~/.claude` (backup first) and unsets `ANTHROPIC_API_KEY`;
  `-Force -NoBackup` is the client-exit mode that leaves no residue.

### Changed
- **`setup.ps1` / `setup.sh`** now deploy `brain` as a toolkit item. `playbooks/` is folded into
  the brain (`brain/playbooks/`); the old top-level `playbooks/` is superseded (delete manually).
- **`s.wrap-up` Part C** now routes promote candidates to `brain/concepts/` and `brain/playbooks/`,
  with a scrub-and-record-`origin:` step.

### Notes
- Provenance `origin:` names real clients and the brain deploys everywhere; the cross-engagement
  confidentiality question is deliberately deferred until it's a live concern.

## [1.2.0] — 2026-07-05

### Added
- **`deployment/unix/setup.sh`** — Linux/macOS port of `setup.ps1`. Same audit-or-deploy
  behaviour (clean → deploy; existing config → audit; `--force` → backup then deploy),
  CRLF-normalised hashing, and secret exclusions. Node.js is auto-installed via **nvm**
  (`nvm install --lts` — no sudo, self-sourced for the run); Claude Code via `npm install -g`.
  Unblocks the VPS track.
- **Auto-install in `setup.ps1`** — a missing Node.js is installed via winget and Claude Code
  via npm, so a fresh Windows machine self-provisions instead of only reporting what's missing.

### Notes
- `cleanup.ps1` / `cleanup.sh` remain deferred until the first client-machine clean-exit need.

## [1.1.0] — 2026-06-25

### Fixed
- **`setup.ps1` audit was line-ending-sensitive.** It compared files with a raw byte
  hash (`Get-FileHash`), so a fresh clone checked out as CRLF read as 13 false conflicts
  against an LF working copy. The audit now normalises line endings before hashing
  (binary files fall back to a raw hash), so it reports real content drift only.

### Added
- **`.gitattributes`** (`* text=auto eol=lf`) — fresh clones check out LF, matching the
  authored files, so byte-diffs and the audit stay consistent across machines.

### Notes
- Surfaced by the Step 7 acid test: deploying from a fresh clone produced a wall of
  false conflicts that were purely CRLF vs LF.

## [1.0.0] — 2026-06-25

First consolidated, deployable release. The toolkit is now the single source of truth
for `~/.claude` and can be deployed to any Windows machine.

### Added
- **`CLAUDE.md`** — global operating contract (the "Mr Nigel" identity and working style).
- **`settings.json`** — global Claude Code preferences.
- **`skills/s.wiki/`** — Obsidian-compatible knowledge wiki skill (source/entity/concept/synthesis page types, templates, lint checks).
- **`skills/s.wrap-up/`** — end-of-session ritual; now includes **Part C — Promote**, which flags generalizable lessons for the toolkit.
- **`playbooks/`** — home for client-agnostic lessons distilled from project work.
- **`deployment/windows/setup.ps1`** — audit-or-deploy installer:
  - Clean machine → deploys the toolkit.
  - Existing config → AUDIT MODE (in-sync / conflicts / harvest candidates / would-be-added); changes nothing until reviewed.
  - `-Force` → deploys over an existing config after a lightweight timestamped backup.
  - Never touches secrets (`.credentials.json`, `settings.local.json`) or runtime state.
- **`README.md`** — overview + Windows deployment runbook.
- **`.gitignore`** — excludes secrets, runtime state, and OS/editor noise.

### Notes
- Flat layout: each top-level item maps 1:1 into `~/.claude`.
- API key is never stored in the repo — set `ANTHROPIC_API_KEY` from a password manager at deploy time.
- Unix deploy script (`deployment/unix/setup.sh`) and a guarded `cleanup.ps1` are deferred until needed.
