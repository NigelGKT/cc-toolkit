# Global Brain

The distilled, cross-project knowledge well that rides to every machine. It's an
`s.wiki` vault living inside `cc-toolkit`, so `setup.ps1` / `setup.sh` deploys it to
`~/.claude/cc-toolkit-wiki-brain/` alongside the rest of your toolkit.

Where a **project** wiki brain holds that project's full reasoning, this global brain holds
only what **transfers** — patterns, architectures, and client-agnostic lessons scrubbed of
project specifics.

## Structure

```
cc-toolkit-wiki-brain/
├── wiki-schema.md     — how this vault specializes s.wiki (read this first)
├── index.md           — table of contents
├── log.md             — chronological op log
├── concepts/          — transferable patterns 🟢
├── playbooks/         — client-agnostic lessons & checklists 🟣
├── syntheses/         — filed answers to recurring questions 🟡
├── sources/           — citations when a page needs one ⚫
└── .obsidian/         — graph colour groups (open the folder as an Obsidian vault)
```

## The three flows

1. **Promote (in)** — at session end, `s.wrap-up` Part C flags a generalizable concept or
   lesson. Copy it here from the project wiki, **scrub** all project specifics, set
   `origin:`, re-link, commit, push. It deploys everywhere on the next `setup`.
2. **Query (out)** — before solving something cold: *"what does my brain say about X"* →
   `s.wiki` reads `~/.claude/cc-toolkit-wiki-brain/` and answers with citations.
3. **Lint (maintain)** — periodically ask `s.wiki` to health-check for contradictions,
   stale claims, and orphans.

## The one rule

**Curate in the `cc-toolkit` repo clone — never edit the deployed `~/.claude/cc-toolkit-wiki-brain/`.**
The repo is the source of truth; the deployed copy is a target. Edit → commit → push →
redeploy, same one-way flow as all your config.

## Open Obsidian on it

Point Obsidian at the `cc-toolkit-wiki-brain/` folder (or the whole `cc-toolkit` repo). The graph view
colour-codes by folder: concepts green, playbooks violet, syntheses yellow, sources grey.
