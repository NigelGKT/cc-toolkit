# cc-toolkit — Live Status (working tier)

> **Read this first when picking up cc-toolkit.** The working-memory tier: where we are right now
> and what's next — **state + intent only**. History, SHAs, and commit/push state live in `git`
> (`git log`, `git status`), not here; per-session synthesis and the changelog archive live in
> `cc-toolkit-wiki-brain/syntheses/`. This project's `CLAUDE.md` **is** the global operating
> contract (deployed to `~/.claude`), so it carries no project pointer — this file is it.
> Last updated: 2026-07-18.
>
> *(Scope split: this file = cc-toolkit's live working state. Meta-roadmap / phase direction lives
> in the `fde-toolkit` brain.)*

## Where we are

- **Last released: v1.20.0 — settings.json drift root-fixed; harvest-reads-disk confirmed by design.**
  `setup.ps1`'s `$SettingsRuntimeKeys` (the list of keys ignored when comparing `settings.json`) now
  also drops `model` and `effortLevel` — the only two keys that ever differ between the repo and a
  live machine, both rewritten at runtime by `/model` and the effort toggle. This root-fixes the
  recurring SessionStart drift nag the same way the plugin-hydration keys were handled before it.
  Separately decided (no code change): the harvest scanning the raw `~/.claude` disk — including
  gitignored files — is the **intended** design, not a bug. `.gitignore` filters noise out of the
  *git repo* at commit/push (the ship skill's stage-by-name), not out of the folder; the scanner
  reading the disk 1:1 is what keeps `~/.claude` and the repo folder in sync.
- **Prior: v1.19.0** — `s.ship-cc-tlkit` single-pass release conductor + retrieve-don't-duplicate
  cleanup. Run `git log` for the commit trail.

## Next step

- **Pick the next open thread.** The natural follow-on is the **`s.wrap-up` visibility mirror** —
  incident question 2 for `s.wrap-up`: a wrong wiki probe *silently skips* the session note, so the
  fix there is a **visibility** surface, not a write-guard. Standing threads below.

## Open threads

- **`s.ship-cc-tlkit` Step 1 wording** — it implies `-Harvest -Force` is unconditional. When a
  session authors **directly in the repo** (as v1.19.0's and v1.20.0's own did), harvest is a correct
  no-op and the dry-run says so; forcing it would only import noise. The skill should state that
  explicitly.
- **Harness pass 2** — session lifecycle & harness surface (plan mode, subagents, hook mechanics,
  permission model, statusline). Scoped out of v1.15.0.
- **`setup.sh` parity** for the harvest/anchor features (`-Harvest`/`-Check`/`CC_TOOLKIT_HOME`,
  and now `$SettingsRuntimeKeys`) — a mechanical follow-on (Windows-primary; Unix deferred).
- **v1.14.0 has no session note** — backfill or let it lie.
- **`settings.json` working-tree copy still dirty** — pre-existing unrelated drift (key reorder +
  runtime keys), excluded from every commit by name. `git checkout -- settings.json` would clear it
  outright; low priority since it never rides along.

## Reference

- Global brain: `cc-toolkit-wiki-brain/` (rides to every machine via deploy) — dual charter:
  transferable knowledge (`concepts/`/`playbooks/`) + self-documentation (`harness/`, `incidents/`).
- Lifecycle: `/s.ship-cc-tlkit` conducts the round-trip; the primitives underneath are `setup.ps1`
  (`-Force` deploy down, `-Harvest` copy up, `-Check` drift). Full runbook:
  `cc-toolkit-wiki-brain/playbooks/cc-toolkit-deploy-lifecycle.md`.

---

*History → `git`. Synthesis/decisions → `cc-toolkit-wiki-brain/`. This file is state + intent only —
keep it short and current.*
