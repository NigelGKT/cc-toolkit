# cc-toolkit — Live Status (working tier)

> **Read this first when picking up cc-toolkit.** The working-memory tier: where we are right now
> and what's next — **state + intent only**. History, SHAs, and commit/push state live in `git`
> (`git log`, `git status`), not here; per-session synthesis and the changelog archive live in
> `cc-toolkit-wiki-brain/syntheses/`. This project's `CLAUDE.md` **is** the global operating
> contract (deployed to `~/.claude`), so it carries no project pointer — this file is it.
> Last updated: 2026-07-17.
>
> *(Scope split: this file = cc-toolkit's live working state. Meta-roadmap / phase direction lives
> in the `fde-toolkit` brain.)*

## Where we are

- **Last released: v1.19.0 — single-pass release flow + retrieve-don't-duplicate cleanup.** A new conductor
  skill, **`s.ship-cc-tlkit`**, runs the whole toolkit round-trip in one pass (harvest up → author
  docs in the repo → one gate → commit + push → deploy down), replacing the prose close-out runbook
  whose unenforced "step 6" drifted three times. Alongside it: `setup.ps1` now persists
  `CC_TOOLKIT_HOME` at User scope on every deploy (so a fresh machine has an anchor without anyone
  setting it by hand), and both `drift-check.ps1` and the skill's guard now **resolve it from the
  persisted scope rather than the process env** — a session inherits its environment at launch, so
  `$env:CC_TOOLKIT_HOME` is empty in any session started without it, which is what made the hook
  fire in some sessions and silently no-op in others. STATUS trimmed to state + intent; CHANGELOG
  thinned to a signpost; the retrieve-don't-duplicate rule encoded in `CLAUDE.md`.
- **Prior: v1.18.0** — `s.wiki` Bootstrap Step 0 safety gate (refuses to scaffold into a populated
  target). Run `git log` for the commit trail.

## Next step

- **Pick the next open thread.** The natural follow-on is the **`s.wrap-up` visibility mirror** —
  incident question 2 for `s.wrap-up`: a wrong wiki probe *silently skips* the session note, so the
  fix there is a **visibility** surface, not a write-guard. Standing threads below.

## Open threads

- **Do not stage `settings.json`.** It shows modified from unrelated drift (local `effortLevel` vs
  repo) swept up by the harvest's all-or-nothing scan; `/model` also writes here. Decide it
  separately — the ship skill stages by name so it never rides along. Root-fix (exclude it from the
  scan) is its own thread.
- **Harvest doesn't respect `.gitignore`** — it enumerates the filesystem, so gitignored runtime
  state (e.g. `.obsidian/workspace.json`) shows in the drift scan. Benign today; symmetric fix is to
  exclude gitignored paths from the scan.
- **`s.ship-cc-tlkit` Step 1 wording** — it implies `-Harvest -Force` is unconditional. When a
  session authors **directly in the repo** (as v1.19.0's own did), harvest is a correct no-op and the
  dry-run says so; forcing it would only import noise. The skill should state that explicitly.
- **Harness pass 2** — session lifecycle & harness surface (plan mode, subagents, hook mechanics,
  permission model, statusline). Scoped out of v1.15.0.
- **`setup.sh` parity** for the harvest/anchor features (`-Harvest`/`-Check`/`CC_TOOLKIT_HOME`) — a
  mechanical follow-on (Windows-primary; Unix deferred).
- **v1.14.0 has no session note** — backfill or let it lie.

## Reference

- Global brain: `cc-toolkit-wiki-brain/` (rides to every machine via deploy) — dual charter:
  transferable knowledge (`concepts/`/`playbooks/`) + self-documentation (`harness/`, `incidents/`).
- Lifecycle: `/s.ship-cc-tlkit` conducts the round-trip; the primitives underneath are `setup.ps1`
  (`-Force` deploy down, `-Harvest` copy up, `-Check` drift). Full runbook:
  `cc-toolkit-wiki-brain/playbooks/cc-toolkit-deploy-lifecycle.md`.

---

*History → `git`. Synthesis/decisions → `cc-toolkit-wiki-brain/`. This file is state + intent only —
keep it short and current.*
