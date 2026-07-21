# Global Brain — Index

The cross-project knowledge well. Deploys to every machine via `cc-toolkit`.
Last updated: 2026-07-21.

## Concepts

- [[concepts/fifo-vs-vwap-cost-basis]] — realized (FIFO) vs floating (VWAP) attribution, and unifying on FIFO-remainder
- [[concepts/convert-at-edge-display-lens]] — present values in a chosen unit without mutating state
- [[concepts/cost-layer-as-derived-view]] — layer commissions/fees as a derived view; never mutate gross
- [[concepts/declarative-intent-over-materialized-state]] — version declarative intent; rehydrate heavy/machine-specific state on deploy (npm lockfile pattern)
- [[concepts/harvest-mirrors-disk-filter-at-commit]] — a mirroring scanner reads its source 1:1, unfiltered; exclusion rules apply once, at commit/publish, not at scan time
- [[concepts/plan-mode-output-durability]] — plan-mode output is transient; freeze a dated, versioned copy into the project's own durable memory before it can be lost

## Playbooks

Client-agnostic lessons and checklists — see [[playbooks/README|playbooks/]] for the zone's charter.

- [[playbooks/cc-toolkit-deploy-lifecycle]] — the toolkit's own runbook: spin up → work → grow the brain → clean exit (with flowchart)
- [[playbooks/prove-empty-diff-before-consolidating]] — before merging diverged duplicate code, prove the observable diff is empty: trace upstream (can the divergent input occur?) + downstream (does a shared formatter already normalize it?) before consolidating
- [[playbooks/behaviour-preserving-refactor-workflow]] — tiered, equivalence-verified loop for refactoring a live system without changing observable behaviour: recon the live counterpart, re-verify stale audits, per-item verify+commit, human gate for what no harness covers
- [[playbooks/venv-setup-workflow]] — Python venv/requirements.txt setup via `scripts/new-pyproject.ps1` + `/s.venv-setup`: import-scan-driven sync, one-package-at-a-time install, delete-and-rerun on breakage

## Harness

Self-documentation of the Claude Code toolkit itself — see [[harness/README|harness/]] for the zone's charter.

- [[harness/harness-overview]] — anchor note: meta-map of the whole `~/.claude` tooling (with flowchart)
- [[harness/memory-architecture]] — the two memory systems (harness auto-memory vs. the three-tier project convention) and the routing rule between them
- [[harness/skills-catalog]] — `s.wiki`, `s.wrap-up`, `s.goal-run`, `s.ship-cc-tlkit`, and the `obsidian@obsidian-skills` plugin bundle: triggers + flows
- [[harness/session-lifecycle]] — plan mode, the Explore/Plan subagent split, and the one-task-per-session → checkpoint → `/clear` cadence (with flowchart)
- [[harness/hooks-and-permissions]] — hook mechanics, the settings.json/settings.local.json split, the permission allow/deny model, and the statusline (pass 2)

## Incidents

How the toolkit has failed — open questions with evidence attached, **not** settled guidance. See [[incidents/README|incidents/]] for the zone's charter and lifecycle.

- 🔴 **open** — [[incidents/2026-07-16-self-description-drift]] — three self-description failures in one session (stale invariant / blind wiki probes / stale STATUS.md); nothing in the system could detect any of them. Root causes known; question 2 (Bootstrap self-guard) shipped for `s.wiki` in v1.18.0; question 5 answered at root in v1.19.0 (STATUS stopped storing what git owns, so it can no longer be false at rest); Layer 2, Q3 and Q7's breadth still open.

## Syntheses

- [[syntheses/2026-07-10-session-plugin-harvest]] — plugin harvest + hydrate for cc-toolkit (v1.8.0)
- [[syntheses/2026-07-15-session-harvest-systematization]] — file harvest (-Harvest) + direction-aware audit + drift-check hook + settings.json semantic compare (v1.12.0–v1.13.0)
- [[syntheses/2026-07-15-session-three-tier-memory-architecture]] — three-tier memory convention (CLAUDE.md/STATUS.md/wiki brain) adopted by cc-toolkit itself (v1.14.0) — *backfilled 2026-07-19*
- [[syntheses/2026-07-16-session-harness-zone-and-wiki-detection]] — dual charter + `harness/` zone, stale invariant amended, `/s.wiki` bootstrap footgun fixed (v1.15.0–v1.16.0)
- [[syntheses/2026-07-17-session-bootstrap-self-guard]] — `s.wiki` Bootstrap Step 0 safety gate: refuse to scaffold into a populated target (incident Q2, v1.18.0)
- [[syntheses/2026-07-17-session-single-pass-release-flow]] — `s.ship-cc-tlkit` single-pass release conductor; STATUS ledger removed + CHANGELOG frozen (retrieve-don't-duplicate); incident Q5 answered at root (v1.19.0)
- [[syntheses/2026-07-18-session-settings-drift-runtime-keys]] — `settings.json` drift root-fixed (`model`/`effortLevel` added to runtime-key ignore list); harvest-reads-disk-then-filter-at-commit confirmed as intended design, not a bug (v1.20.0)
- [[syntheses/2026-07-20-session-obsidian-tracking-and-workflow-decision]] — Obsidian `.gitignore` scope corrected (all vault settings now tracked, not just graph.json); repo-vs-harvest workflow split confirmed, not collapsed (v1.22.0)
- [[syntheses/2026-07-20-session-wiki-brain-lint-and-log-restructure]] — first `s.wiki` lint pass on this brain (9 findings, 7 fixed); `log.md` re-sorted to strict chronological order; `brain.base` added for a live sortable/filterable page-state view (v1.23.0)
- [[syntheses/2026-07-20-session-refactor-playbooks-and-promotion-autoapply]] — 2 new playbooks (behaviour-preserving refactor workflow, prove-empty-diff-before-consolidating); `s.wrap-up` Part C now applies prose promotions on confirmation instead of flag-only (v1.24.0)
- [[syntheses/2026-07-21-session-venv-setup-centralization]] — `new-pyproject.ps1` folded into cc-toolkit as `scripts/new-pyproject.ps1` + new `s.venv-setup` skill; `README.md` staleness fixed (repo-first workflow, folder tree); new `venv-setup-workflow` playbook (v1.25.0)
