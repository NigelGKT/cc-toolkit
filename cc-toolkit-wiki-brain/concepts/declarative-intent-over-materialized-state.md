---
type: concept
tags: [config-as-code, deploy, idempotency, state-management]
origin: GKT cc-toolkit (plugin harvest + hydrate, 2026)
sources: []
updated: 2026-07-10
status: stable
---

# Declarative Intent over Materialized State

When a system's on-disk state is **heavy, self-updating, and machine-specific**, don't
version the state — version the **minimal declarative intent** that regenerates it, and
**rehydrate** the materialized form on deploy.

## The principle
Split any managed directory into three tiers:
1. **Declarative intent** — the small, portable source of truth (which sources, which items). Version this.
2. **Materialized content** — bulky, re-fetchable, reconstructable from the intent. Never version.
3. **Runtime state** — caches, timestamps, absolute paths, installer bookkeeping. Never version.

The canonical instance is **npm**: commit `package.json` (intent), gitignore `node_modules/`
(materialized), and `npm install` rehydrates. The same split fits any "config-as-code
deployed to disposable machines" setup — editor/agent plugins, IDE extensions, provisioned
tool sets.

## Why it matters
- **Portability** — intent carries no machine-specific paths; materialized state is riddled with them (absolute install paths, timestamps, install SHAs), so versioning it guarantees cross-machine conflicts.
- **No fighting the manager** — the tool that owns the folder rewrites it on every update; versioning those bytes yields perpetual diff churn. Intent is stable across updates.
- **Clean audit** — comparing *intent* ("is this item declared?") is a set comparison, never a noisy byte-diff.
- **Harvest symmetry** — "pull up" = read live state, strip tiers 2-3, emit tier 1. "Push down" = read tier 1, re-run the installer.

## The trap
Reaching for a whole-folder copy because it "just works" locally. It drags in nested VCS
metadata, bulk, and machine paths, and silently violates the same "no runtime state in the
repo" rule the setup already depends on. The folder looking self-contained is the lure.

## Transfer note
Reach for this whenever you're tempted to commit a directory some tool installs into and
keeps updating (`node_modules`, plugin/extension folders, downloaded model/asset caches,
provisioned CLIs). Find the smallest declarative descriptor the tool can rebuild from,
version only that, and make deploy re-run the installer — idempotently, tolerant of the
installer being absent or offline.

## Related
- [[../playbooks/cc-toolkit-deploy-lifecycle]] — where this is applied (plugins hydrated, not copied)

## Sources
- Derived from the cc-toolkit plugin harvest/hydrate design (2026-07-10).
