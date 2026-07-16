# cc-toolkit — Live Status (repo / config / deploy state)

> **Read this first when picking up cc-toolkit.** Single source of truth for the repo's
> current version, what's deployed, and what's pending harvest/commit. This project's
> `CLAUDE.md` **is** the global operating contract (deployed to `~/.claude`), so it holds no
> project-specific pointer — this STATUS.md is the project working tier. Last updated: 2026-07-16.
>
> *(Scope split: this file = cc-toolkit's repo/config/deploy state. The `fde-toolkit` STATUS.md
> holds the meta-roadmap / phase direction.)*

## Version

- **Last released: v1.14.0** (2026-07-15, commit `2378a73`) — the three-tier memory
  architecture. See `CHANGELOG.md`.
- **Harvested into the working tree, not yet committed (this session)** — two versions' worth,
  intended as **three commits** (feature, fix, then the session note separately, per the
  `376646e` precedent where one note covered v1.12.0 + v1.13.0):
  - **v1.15.0** — a `harness/` zone in `cc-toolkit-wiki-brain/`: self-documentation of the
    toolkit itself (memory routing, deploy/harvest lifecycle, skills catalog), distinct from the
    brain's transferable-patterns charter. `wiki-schema.md` amended to a formal dual charter; the
    deploy playbook extended with the file-harvest + drift-check-hook runbooks it was missing;
    the stale "never edit the deployed copy" invariant amended (it predated `-Harvest`).
  - **v1.16.0** — wiki detection fix. `/s.wiki` from the repo root would have **bootstrapped a
    fresh vault over it**; `s.wrap-up` silently skipped its session note for the same reason.
    Scope-gated `## Wiki` pointer in the global `CLAUDE.md` + subfolder-glob fallback in both
    skill probes + session close-out runbook.
  - **Session note** — `syntheses/2026-07-16-session-harness-zone-and-wiki-detection.md`,
    covering both versions.

  All authored in `~/.claude/cc-toolkit-wiki-brain/` and harvested up — see the new close-out
  runbook in the deploy playbook for why that takes two `-Harvest` passes.

## Deploy state

- `setup.ps1 -Force` was last run 2026-07-15 → `~/.claude` carries the three-tier foundation
  (backup at `~/.claude.backup-20260715-213222`). Plugins re-hydrated from `plugins.json`.
- Deploy manifest (`$ToolkitItems`): `CLAUDE.md`, `settings.json`, `skills/`,
  `cc-toolkit-wiki-brain/`, `statusline.js`, `drift-check.ps1`. **STATUS.md is not deployed** —
  it stays repo-local by design.

## Pending / open threads

- **Commit + push** the three commits above.
- **Do not stage `settings.json`.** It shows modified from an unrelated pre-existing drift
  (local `effortLevel: xhigh` vs repo `high`) swept up by the harvest's all-or-nothing file
  scan — this thread is still open, decide it separately. Note `/model` writes here too, so it
  can pick up an unintended global default-model change; stage by name, never `git add -A`.
- **Harvest doesn't respect `.gitignore`** — it enumerates the filesystem, so gitignored runtime
  state (e.g. `.obsidian/workspace.json`) shows up in the drift scan. Benign today, but on the
  `LocalNewer` side it would nag "not yet harvested" over an uncommittable file — the same
  alarm-fatigue class as the `settings.json` false-positive fixed in v1.13.0. Symmetric fix:
  exclude gitignored paths from the scan.
- **Harness pass 2** — session lifecycle & harness surface (plan mode, Explore/Plan subagents,
  one-task-per-session → checkpoint → `/clear`, hook mechanics, `settings.json` permission model,
  statusline). Deliberately scoped out of v1.15.0.
- **`setup.sh` parity** for the harvest features (`-Harvest`/`-Check`) is a mechanical follow-on
  (Windows-primary; Unix deferred).
- **v1.14.0 has no session note** — syntheses jump 07-10 → 07-15 and that note covers v1.12/v1.13
  only. Backfill or let it lie.

## Reference

- Global brain: `cc-toolkit-wiki-brain/` (rides to every machine via deploy) — dual charter as
  of v1.15.0: `concepts/`/`playbooks/` (transferable knowledge) + `harness/` (toolkit
  self-documentation). Reused as-is — not a per-project brain.
- Harvest/deploy lifecycle: `setup.ps1` (`-Force` deploy down, `-Harvest` copy up, `-Check` drift).

---

*Long-term design rationale + roadmap live in the `fde-toolkit` brain; transferable playbooks in
`cc-toolkit-wiki-brain/`. This file is the hot/working tier — keep it short and current.*
