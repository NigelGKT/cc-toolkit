# Global Brain — Log

Chronological record of brain operations. Format: `## [YYYY-MM-DD HH:MM] <op> | <subject>`
where `op` ∈ {bootstrap, ingest, promote, query, lint, manual}.

## [2026-07-06 00:00] bootstrap | Global brain — cross-project distilled patterns & lessons

## [2026-07-06 00:00] promote | Seed 3 concepts from Propex PTA wiki (scrubbed to patterns)
- New: [[concepts/fifo-vs-vwap-cost-basis]], [[concepts/convert-at-edge-display-lens]], [[concepts/cost-layer-as-derived-view]]
- Origin: Propex Trading (PNL analytics engine, 2026)
- Scrub: client name, file/function/line references, and raw rate data removed from bodies; origin retained in frontmatter

## [2026-07-10 23:51] promote | Concept — declarative intent over materialized state
- New: [[concepts/declarative-intent-over-materialized-state]]
- Origin: GKT cc-toolkit (plugin harvest + hydrate, 2026)

## [2026-07-10 23:51] ingest | Session note — cc-toolkit plugin harvest + hydrate

## [2026-07-15 19:00] ingest | Session note — cc-toolkit harvest systematization (v1.12.0 + v1.13.0)
- Session: [[syntheses/2026-07-15-session-harvest-systematization]]
- Promote candidate flagged (local↔source sync needs a harvest-up path + drift detection); not yet filed

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
- Updated: [[playbooks/cc-toolkit-deploy-lifecycle]] — general file-harvest runbook, drift-check hook runbook, invariant amendment, harness cross-links
- Graph: `.obsidian/graph.json` — new colour group for `path:harness/`
