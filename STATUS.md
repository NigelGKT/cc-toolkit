# cc-toolkit — Live Status (working tier)

> **Read this first when picking up cc-toolkit.** The working-memory tier: where we are right now
> and what's next — **state + intent only**. History, SHAs, and commit/push state live in `git`
> (`git log`, `git status`), not here; per-session synthesis and the changelog archive live in
> `cc-toolkit-wiki-brain/syntheses/`. This project's `CLAUDE.md` **is** the global operating
> contract (deployed to `~/.claude`), so it carries no project pointer — this file is it.
> Last updated: 2026-07-19.
>
> *(Scope split: this file = cc-toolkit's live working state. Meta-roadmap / phase direction lives
> in the `fde-toolkit` brain.)*

## Where we are

- **Uncommitted, ready to ship as v1.21.0 — harness pass 2 + setup.sh parity + v1.14.0 backfill.**
  Three threads closed in one sitting:
  - **Harness pass 2**: two new self-documentation pages, [[harness/session-lifecycle]] (plan
    mode, the Explore/Plan subagent split, checkpoint → `/clear`) and
    [[harness/hooks-and-permissions]] (hook mechanics, the settings.json/settings.local.json
    split, the permission allow/deny model, statusline) — closes the gap `harness-overview.md`
    flagged since v1.15.0.
  - **`setup.sh` parity**: ported `--harvest`/`--harvest --force`, `--check`, the semantic
    `settings.json` compare (mirrors v1.20.0's `$SettingsRuntimeKeys` fix), and the
    `CC_TOOLKIT_HOME` anchor (a marker file, not a shell-rc export) — plus a real `set -e` +
    nested-pipeline bug found and fixed along the way (every run crashed without it). Verified
    by actually executing every mode against a disposable fixture, not just reading the diff.
  - **v1.14.0 backfill**: [[syntheses/2026-07-15-session-three-tier-memory-architecture]]
    reconstructed from commit `2378a73`, marked as backfilled.
- **Prior: v1.20.0** — settings.json drift root-fixed via `$SettingsRuntimeKeys`; harvest-reads-disk
  confirmed as intended design. Run `git log` for the full commit trail.

## Next step

- **Ship v1.21.0** via `/s.ship-cc-tlkit`, or continue to the next open thread first — both viable,
  nothing is blocking either way.

## Open threads

- **`s.ship-cc-tlkit` Step 1 wording** — it implies `-Harvest -Force` is unconditional. When a
  session authors **directly in the repo** (as several recent sessions' own did), harvest is a
  correct no-op and the dry-run says so; forcing it would only import noise. The skill should state
  that explicitly.
- **Cross-platform `SessionStart` hook wiring** — the hook command is hardcoded to
  `powershell -NoProfile -File ~/.claude/drift-check.ps1` in the one shared `settings.json`, so
  even with `setup.sh --check` now built, nothing auto-invokes it on a Mac/Linux machine. Needs a
  `drift-check.sh` plus a way for the hook to pick the right script per OS — a real design question,
  not a mechanical port. Zero live impact today (Windows-primary); found during the v1.21.0
  `setup.sh` parity work.
- **`settings.json` working-tree copy still dirty** — pre-existing unrelated drift (key reorder +
  runtime keys), excluded from every commit by name. `git checkout -- settings.json` would clear it
  outright; low priority since it never rides along.
- **Deploy-DOWN still overwrites live `model`/`effortLevel`** from the master on `-Force`/`--force`
  (both Windows and now Unix) — rare, and arguably fine; a merge-instead-of-copy for those two keys
  is a separate optional fix. Noted since v1.20.0.

## Reference

- Global brain: `cc-toolkit-wiki-brain/` (rides to every machine via deploy) — dual charter:
  transferable knowledge (`concepts/`/`playbooks/`) + self-documentation (`harness/`, `incidents/`).
- Lifecycle: `/s.ship-cc-tlkit` conducts the round-trip; the primitives underneath are `setup.ps1`
  (`-Force` deploy down, `-Harvest` copy up, `-Check` drift). Full runbook:
  `cc-toolkit-wiki-brain/playbooks/cc-toolkit-deploy-lifecycle.md`.

---

*History → `git`. Synthesis/decisions → `cc-toolkit-wiki-brain/`. This file is state + intent only —
keep it short and current.*
