# Global Brain — Log

Chronological record of brain operations, newest first. Format: `## [YYYY-MM-DD HH:MM] <op> | <subject>`
where `op` ∈ {bootstrap, ingest, promote, query, lint, manual}. For a live, sortable/filterable view
of current page state (type/status/updated/origin/tags), see [[brain.base]] — this log stays the
append-only record of *what happened and why*, which a Base view can't reconstruct.

## [2026-07-21 17:00] promote | Concept — plan-mode output durability
- New page: [[concepts/plan-mode-output-durability]]
- Updated: [[index]] (Concepts entry added)
- Origin: Propex Trading Analytics — the I07 reconciliation replan lost its original 2026-05-26
  plan-mode design file to a machine/version change, ~16 versions later. The replan's fix (freeze
  a dated, versioned copy of any plan with lasting value into the project's own wiki) generalizes
  beyond that project — promoted here.
- Landed straight in the repo clone this time (not the deploy copy) — the `s.wrap-up` Part C fix
  applied earlier this session now authors here by default via `CC_TOOLKIT_HOME`.

## [2026-07-21 13:30] promote | Playbook — Python venv setup workflow
- New page: [[playbooks/venv-setup-workflow]]
- Updated: [[index]] (Playbooks entry added)
- Origin: `pyvenv_scripts`/`NigelGKT/scripts` repo's `new-pyproject.ps1` + `PY_VENV_WORKFLOW.md` —
  folded into cc-toolkit as `scripts/new-pyproject.ps1` + the new `s.venv-setup` skill, so the
  venv-setup tool is native to the toolkit instead of a separate referenced project.

## [2026-07-20 20:15] ingest | Session note — refactor/dedup playbooks + s.wrap-up promotion auto-apply
- Session: [[syntheses/2026-07-20-session-refactor-playbooks-and-promotion-autoapply]]

## [2026-07-20 20:00] promote | Playbook — behaviour-preserving refactor workflow
- New page: [[playbooks/behaviour-preserving-refactor-workflow]]
- Updated: [[index]] (Playbooks entry added)
- Origin: Propex Trading (PNL analytics engine) — distilled from the I06 refactor audit's three
  tiers (Tier A/B/C, sessions 2026-07-04/07-06/07-20): tiered risk sequencing, live-counterpart
  recon/isolation, stale-audit re-verification, per-item behavioural-equivalence harnesses
  (mutation-tested), and the human-gate/merge-boundary rules. Scrubbed to a general pattern;
  automation counterpart is the `s.goal-run` skill.

## [2026-07-20 19:45] promote | Playbook — prove the diff is empty before consolidating diverged duplicates
- New page: [[playbooks/prove-empty-diff-before-consolidating]]
- Updated: [[index]] (Playbooks entry added)
- Origin: Propex Trading (PNL analytics webapp) — distilled from the BUG-W9a de-dup, where two diverged VWAP null-checks proved behaviourally identical (serializer never omits the key upstream; shared `fmt()` collapses null+undefined downstream). Scrubbed to a general upstream/downstream reachability checklist.

## [2026-07-20 14:44] ingest | Session note — wiki brain lint pass + log.md restructure + brain.base
- Session: [[syntheses/2026-07-20-session-wiki-brain-lint-and-log-restructure]]

## [2026-07-20 13:50] lint | 9 findings (4 high, 4 medium, 1 low) — 7 fixed, 2 findings rejected on review (misfile call on the deploy-lifecycle playbook: harness/README already cross-references it as the intentional runbook counterpart to its architecture note; the "unconditional harvest" wording issue lives in `s.ship-cc-tlkit` itself, not in any wiki page)

## [2026-07-20 13:50] promote | Concept — harvest mirrors disk, filters at commit
- New: [[concepts/harvest-mirrors-disk-filter-at-commit]]
- Origin: GKT cc-toolkit (harvest/deploy scanner design, 2026)
- Closes the promote-candidate thread flagged in the 2026-07-16 and 2026-07-18 session notes

## [2026-07-20 13:00] ingest | Session note — Obsidian tracking + workflow split decision (v1.22.0)
- Session: [[syntheses/2026-07-20-session-obsidian-tracking-and-workflow-decision]]
- `.gitignore`: removed the `.obsidian/*` exclusion — `app.json`/`appearance.json`/`core-plugins.json`/`workspace.json` now tracked alongside `graph.json`, so a fresh clone opens the wiki with the same workspace layout
- Decided (no code change): keep both editing workflows (repo-direct for toolkit-dev sessions, `~/.claude`+harvest for incidental edits) rather than collapsing to one — confirms existing `wiki-schema.md` guidance rather than changing it

## [2026-07-18 16:53] ingest | Session note — settings.json drift root-fix + harvest-reads-disk decision (v1.20.0)
- Session: [[syntheses/2026-07-18-session-settings-drift-runtime-keys]]
- `setup.ps1`: `model` + `effortLevel` added to `$SettingsRuntimeKeys` — the only two keys that ever
  drift are the two `/model`/effort-toggle rewrite at runtime; root-fixes the recurring SessionStart
  nag. Verified via `-Harvest` dry-run (CHANGED-UP → nothing to harvest).
- Decision (no code change): harvest reading the live `~/.claude` disk is the intended design, not a
  `.gitignore` bug — `.gitignore` filters noise out of the git repo at commit/push, not out of the
  folder, so the scanner reading the disk 1:1 is correct; the ship skill's stage-by-name is the filter.

## [2026-07-18 16:00] ingest | Harness pass 2 — session lifecycle + hooks/permissions/statusline — *backfilled 2026-07-20*
- New: [[harness/session-lifecycle]], [[harness/hooks-and-permissions]]
- Closes the "Harness pass 2" deferred item from the 2026-07-16 session note

## [2026-07-17 18:00] ingest | Session note — single-pass release flow, s.ship-cc-tlkit (v1.19.0)
- Session: [[syntheses/2026-07-17-session-single-pass-release-flow]]
- New skill `s.ship-cc-tlkit`: conducts the whole round-trip in one pass (harvest → docs authored in the repo → one gate → commit + push → deploy down); replaces the six-step prose close-out runbook
- Root-caused the STATUS drift: it stored commit/SHA state git already owns, so it was false at rest **by construction**. Removed the data (STATUS → state + intent only) — step 6 no longer exists
- `CHANGELOG.md` frozen to a signpost (a third copy of a record git + `syntheses/` already hold); `CLAUDE.md` gained the *retrieve, don't duplicate* rule (git = history, wiki = synthesis, web = cached answer + source URL)
- Anchor: `setup.ps1` persists `CC_TOOLKIT_HOME` on deploy; `drift-check.ps1` + the skill guard now read the **persisted scope**, not the process env — which is why the hook fired in some sessions and silently no-op'd in others
- Updated: [[incidents/2026-07-16-self-description-drift]] — Q5 answered at root (remove the false-able data rather than reorder the ritual), Q7 partial; [[playbooks/cc-toolkit-deploy-lifecycle]] + [[harness/skills-catalog]] rewritten to the single-pass flow

## [2026-07-17 00:00] ingest | Session note — s.wiki Bootstrap self-guard (v1.18.0)
- Session: [[syntheses/2026-07-17-session-bootstrap-self-guard]]
- Shipped incident Q2 for `s.wiki`: Bootstrap Step 0 safety gate refuses to scaffold into a non-empty `WIKI_ROOT` (repo root / project root / any pre-existing files) without explicit confirmation
- Verified by scratch-fixture simulation; true end-to-end run deferred (needs skill reload)
- Updated: [[incidents/2026-07-16-self-description-drift]] — Q2 marked shipped for `s.wiki`; `s.wrap-up` mirror failure (silent omission, not destruction) left open for a visibility fix

## [2026-07-16 02:30] manual | Incident update — Failure 3 recurred a 3rd time (v1.17.0 closeout)
- Updated: [[incidents/2026-07-16-self-description-drift]] — v1.17.0 (`ec8fb35`) was committed skipping its CHANGELOG entry + step-6 STATUS refresh: the identical drift, after the fix, same session
- Sharpest evidence for open Q5/Q7: step 6 is unenforced prose, so it did not fire
- Closeout paperwork done (CHANGELOG v1.17.0 + STATUS refresh); incident stays `open`

## [2026-07-16 02:00] manual | Incident capture — self-description drift (new incidents/ zone)
- New: [[incidents/2026-07-16-self-description-drift]] (`status: open`), [[incidents/README]]
- Schema: [[wiki-schema]] — `incidents/` registered under the self-documentation charter; `incident` page type with its own lifecycle vocabulary (`open`/`analyzed`/`resolved`, overriding the brain-wide reliability statuses); graph colour group 🔴 `path:incidents/`
- Captures three failures + the agent-behaviour layer; finding is that none were detectable — the toolkit has drift detection for files, none for semantic self-description
- **Open, not resolved** — parked for deliberate design work; highest-leverage unshipped candidate is a Bootstrap self-guard (refuse to scaffold into a populated folder)

## [2026-07-16 01:00] ingest | Session note — harness zone + wiki detection (v1.15.0 + v1.16.0)
- Session: [[syntheses/2026-07-16-session-harness-zone-and-wiki-detection]]
- Covers both versions in one note (precedent: the 2026-07-15 note covered v1.12.0 + v1.13.0)

## [2026-07-16 00:30] manual | Fix wiki detection — subfolder brains + scope-gated global pointer
- Global `CLAUDE.md`: new scope-gated `## Wiki` section (applies only to `cc-toolkit` / `~/.claude` roots)
- `s.wiki` + `s.wrap-up` probes: glob one level down for `*/wiki-schema.md` before concluding "no wiki"
- Root cause: `/s.wiki` from the cc-toolkit root would bootstrap a fresh vault over the repo — both probes missed the subfolder brain, and cc-toolkit's CLAUDE.md *is* the global contract so it carried no pointer
- Updated: [[playbooks/cc-toolkit-deploy-lifecycle]] — session close-out runbook (work → harvest → wrap-up → harvest → commit)

## [2026-07-16 00:00] manual | Dual charter — add harness/ zone for toolkit self-documentation
- Schema: [[wiki-schema]] amended — dual charter declared, `harness` page type registered, 2 house-style carve-outs added, curation invariant amended (local editing via `-Harvest` now explicitly supported)
- New: [[harness/README]], [[harness/harness-overview]], [[harness/memory-architecture]], [[harness/skills-catalog]]

## [2026-07-15 23:43] ingest | Session note — three-tier memory architecture (v1.14.0) — *backfilled 2026-07-19*
- Session: [[syntheses/2026-07-15-session-three-tier-memory-architecture]]
- Reconstructed from commit `2378a73`, not written live — this session sat in the gap between the 2026-07-10 and 2026-07-15 notes
- Global `CLAUDE.md` gained the `## Memory architecture` contract (CLAUDE.md/STATUS.md/wiki brain, split by rate-of-change); `s.wiki` bootstrap now scaffolds `STATUS.md` + wires a `## Memory` pointer; `s.wrap-up` orients on and writes to `STATUS.md`
- Its own STATUS.md flagged two open threads at the time (settings.json harvest decision, setup.sh parity) — both finally closed 2026-07-18/19
- Updated: [[playbooks/cc-toolkit-deploy-lifecycle]] — general file-harvest runbook, drift-check hook runbook, invariant amendment, harness cross-links
- Graph: `.obsidian/graph.json` — new colour group for `path:harness/`

## [2026-07-15 19:00] ingest | Session note — cc-toolkit harvest systematization (v1.12.0 + v1.13.0)
- Session: [[syntheses/2026-07-15-session-harvest-systematization]]
- Promote candidate flagged (local↔source sync needs a harvest-up path + drift detection); not yet filed

## [2026-07-10 23:51] promote | Concept — declarative intent over materialized state
- New: [[concepts/declarative-intent-over-materialized-state]]
- Origin: GKT cc-toolkit (plugin harvest + hydrate, 2026)

## [2026-07-10 23:51] ingest | Session note — cc-toolkit plugin harvest + hydrate
- Session: [[syntheses/2026-07-10-session-plugin-harvest]]

## [2026-07-06 00:00] promote | Seed 3 concepts from Propex PTA wiki (scrubbed to patterns)
- New: [[concepts/fifo-vs-vwap-cost-basis]], [[concepts/convert-at-edge-display-lens]], [[concepts/cost-layer-as-derived-view]]
- Origin: Propex Trading (PNL analytics engine, 2026)
- Scrub: client name, file/function/line references, and raw rate data removed from bodies; origin retained in frontmatter

## [2026-07-06 00:00] bootstrap | Global brain — cross-project distilled patterns & lessons
