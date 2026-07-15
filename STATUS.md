# cc-toolkit — Live Status (repo / config / deploy state)

> **Read this first when picking up cc-toolkit.** Single source of truth for the repo's
> current version, what's deployed, and what's pending harvest/commit. This project's
> `CLAUDE.md` **is** the global operating contract (deployed to `~/.claude`), so it holds no
> project-specific pointer — this STATUS.md is the project working tier. Last updated: 2026-07-15.
>
> *(Scope split: this file = cc-toolkit's repo/config/deploy state. The `fde-toolkit` STATUS.md
> holds the meta-roadmap / phase direction.)*

## Version

- **Last released: v1.13.0** (2026-07-15) — see `CHANGELOG.md`.
- **Uncommitted in the working tree (this session):** the three-tier memory architecture —
  `CLAUDE.md` `## Memory architecture`, `skills/s.wiki` (new `templates/status.md` + bootstrap
  wiring + ingest boundary), `skills/s.wrap-up` (STATUS.md orientation/write/re-anchor). Will
  become **v1.14.0** on commit + CHANGELOG entry.

## Deploy state

- `setup.ps1 -Force` was run this session → `~/.claude` now carries the three-tier foundation
  (backup at `~/.claude.backup-20260715-213222`). Plugins re-hydrated from `plugins.json`.
- Deploy manifest (`$ToolkitItems`): `CLAUDE.md`, `settings.json`, `skills/`,
  `cc-toolkit-wiki-brain/`, `statusline.js`, `drift-check.ps1`. **STATUS.md is not deployed** —
  it stays repo-local by design.

## Pending / open threads

- **Commit the memory-architecture work** (→ v1.14.0) and push. Then it's harvest-clean.
- **`settings.json` harvest** — local `~/.claude/settings.json` is LOCAL NEWER (`effortLevel:
  xhigh` vs repo `high`; plus live plugin blocks that self-hydrate). Decide whether to harvest
  the `effortLevel` intent up or leave repo at `high`. Run `setup.ps1 -Harvest` to review.
- **`setup.sh` parity** for the harvest features (`-Harvest`/`-Check`) is a mechanical follow-on
  (Windows-primary; Unix deferred).

## Reference

- Global brain: `cc-toolkit-wiki-brain/` (rides to every machine via deploy; has `playbooks/` +
  `concepts/` for transferable knowledge). Reused as-is — not a per-project brain.
- Harvest/deploy lifecycle: `setup.ps1` (`-Force` deploy down, `-Harvest` copy up, `-Check` drift).

---

*Long-term design rationale + roadmap live in the `fde-toolkit` brain; transferable playbooks in
`cc-toolkit-wiki-brain/`. This file is the hot/working tier — keep it short and current.*
