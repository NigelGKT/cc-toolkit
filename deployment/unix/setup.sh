#!/usr/bin/env bash
#
# Deploy the GKT cc-toolkit into this machine's global Claude Code config (~/.claude).
# Linux / macOS counterpart of deployment/windows/setup.ps1.
#
# Safe by default:
#   - CLEAN machine (no existing config): deploys straight away.
#   - EXISTING config detected: does NOT overwrite. It audits what differs, prints a
#     HARVEST report (what's on this machine but not in cc-toolkit), and stops so you
#     can pull anything worth keeping UP into the repo first. Re-run with --force to
#     deploy after review (a lightweight backup of the toolkit files is taken first).
#
#   Never touches secrets (.credentials.json, settings.local.json) or runtime state.
#   All toolkit items are text; CRLF/LF differences are normalised before hashing so
#   the audit reports real drift only.
#
# Plugins (parity with setup.ps1): Claude Code plugins live in ~/.claude/plugins/, which is
# self-updating, machine-path-laden runtime state (gitignored). We version the *intent* in
# plugins.json (marketplaces + plugin names) and re-hydrate the bytes on deploy via the
# claude CLI. JSON is parsed with node (a guaranteed prerequisite), so no jq dependency.
#
# Usage:
#   ./setup.sh                   # clean machine -> deploy; existing config -> audit only
#   ./setup.sh --force           # deploy over an existing config (backup taken first)
#   ./setup.sh --harvest-plugins # regenerate plugins.json from installed plugins, then stop
#
set -euo pipefail

# ── Args ────────────────────────────────────────────────────────────
FORCE=0
HARVEST_PLUGINS=0
for arg in "$@"; do
  case "$arg" in
    --force|-f|-Force) FORCE=1 ;;
    --harvest-plugins|-HarvestPlugins) HARVEST_PLUGINS=1 ;;
    -h|--help)
      sed -n '2,26p' "$0" | sed 's/^#\{0,1\} \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

# ── Colours (fall back to plain if not a TTY) ───────────────────────
if [ -t 1 ]; then
  C_CYAN=$'\033[36m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m';  C_MAGENTA=$'\033[35m'; C_RESET=$'\033[0m'
else
  C_CYAN=; C_GREEN=; C_YELLOW=; C_RED=; C_MAGENTA=; C_RESET=
fi
say()  { printf '%s\n' "$*"; }
sayc() { printf '%s%s%s\n' "$1" "$2" "$C_RESET"; }

# ── Resolve locations ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLAUDE_HOME="$HOME/.claude"

# Toolkit items this repo deploys (relative to repo root).
# 'cc-toolkit-wiki-brain' is the global-brain s.wiki vault (playbooks are folded inside it).
# 'statusline.js' backs the settings.json statusLine command (context %/model/cwd/branch).
TOOLKIT_ITEMS=(CLAUDE.md settings.json skills cc-toolkit-wiki-brain statusline.js)

# Things we must NEVER deploy or overwrite (secrets / local overrides).
NEVER_TOUCH=(.credentials.json settings.local.json)

# Declarative plugin manifest: the marketplaces + installed plugin *names* only.
# ~/.claude/plugins/ itself is runtime state (gitignored) - version the intent, re-hydrate
# the bytes on deploy via the claude CLI.
PLUGIN_MANIFEST="$REPO_ROOT/plugins.json"
MACHINE_PLUGINS_DIR="$CLAUDE_HOME/plugins"
# Marketplaces that ship as Claude Code defaults - skip in harvest unless a listed plugin
# actually depends on one (a plugin's marketplace is the segment after its last '@').
DEFAULT_MARKETPLACES="claude-plugins-official"

say ""
sayc "$C_CYAN" "GKT cc-toolkit setup"
say  "  repo : $REPO_ROOT"
say  "  dest : $CLAUDE_HOME"
say ""

# ── Prerequisite check (git: report only; Node.js + Claude Code: auto-install) ──
say "Prerequisites:"

# git — report only (requires manual install / distro judgment)
if command -v git >/dev/null 2>&1; then
  sayc "$C_GREEN" "  [ok]   git"
else
  sayc "$C_YELLOW" "  [miss] git  ->  install via your package manager (e.g. sudo apt install git)"
fi

# Node.js — auto-install via nvm if missing (no sudo; self-sources for this run)
if command -v node >/dev/null 2>&1; then
  sayc "$C_GREEN" "  [ok]   Node.js"
else
  sayc "$C_YELLOW" "  [miss] Node.js — attempting install via nvm..."
  export NVM_DIR="$HOME/.nvm"
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    if command -v curl >/dev/null 2>&1; then
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    else
      sayc "$C_YELLOW" "  [miss] Node.js  ->  curl unavailable; install nvm or Node.js LTS manually"
    fi
  fi
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  if command -v nvm >/dev/null 2>&1; then
    nvm install --lts
  fi
  if command -v node >/dev/null 2>&1; then
    sayc "$C_GREEN" "  [ok]   Node.js (just installed)"
  else
    sayc "$C_YELLOW" "  [warn] Node.js not active — open a new shell (source ~/.bashrc) then re-run this script."
  fi
fi

# Claude Code — auto-install via npm if missing
if command -v claude >/dev/null 2>&1; then
  sayc "$C_GREEN" "  [ok]   Claude Code"
else
  if command -v npm >/dev/null 2>&1; then
    sayc "$C_YELLOW" "  [miss] Claude Code — installing via npm..."
    npm install -g @anthropic-ai/claude-code
    if command -v claude >/dev/null 2>&1; then
      sayc "$C_GREEN" "  [ok]   Claude Code (just installed)"
    else
      sayc "$C_YELLOW" "  [warn] Claude Code installed — open a new shell then re-run this script."
    fi
  else
    sayc "$C_YELLOW" "  [miss] Claude Code  ->  install Node.js first, then: npm install -g @anthropic-ai/claude-code"
  fi
fi

say ""

# ── Content hash that ignores line endings (CRLF vs LF) ─────────────
# A raw byte hash flags a CRLF-checked-out clone as "different" from an LF
# working copy even when content is identical. Toolkit items are all text,
# so we strip CR before hashing and report real drift only.
sha_sum() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  else
    shasum -a 256 | awk '{print $1}'
  fi
}
hash_file() { tr -d '\r' < "$1" | sha_sum; }

# ── Enumerate files under a toolkit item (file or dir) as "rel<TAB>full" ──
list_item_files() {
  local base="$1" item="$2" p="$1/$2"
  [ -e "$p" ] || return 0
  if [ -f "$p" ]; then
    printf '%s\t%s\n' "$item" "$p"
  else
    find "$p" -type f | while IFS= read -r f; do
      printf '%s\t%s\n' "${f#"$base"/}" "$f"
    done
  fi
}

# ── Plugin state helpers (declarative: marketplaces + plugin names only) ──
# node parses the JSON (guaranteed prerequisite). Each helper degrades to empty output if
# node is missing or a file is absent, so the plugin layer never blocks the core deploy.
have_node() { command -v node >/dev/null 2>&1; }

# Machine marketplaces as "name<TAB>repo" (github sources only).
machine_marketplaces() {
  have_node || return 0
  node -e '
    const fs=require("fs");
    try{const j=JSON.parse((x=>x.charCodeAt(0)===65279?x.slice(1):x)(fs.readFileSync(process.argv[1],"utf8")));
      for(const [n,v] of Object.entries(j)){
        if(v&&v.source&&v.source.source==="github"&&v.source.repo) console.log(n+"\t"+v.source.repo);
      }}catch(e){}
  ' "$MACHINE_PLUGINS_DIR/known_marketplaces.json" 2>/dev/null
}

# Machine installed plugin names (keys of .plugins), one per line.
machine_plugins() {
  have_node || return 0
  node -e '
    const fs=require("fs");
    try{const j=JSON.parse((x=>x.charCodeAt(0)===65279?x.slice(1):x)(fs.readFileSync(process.argv[1],"utf8")));
      if(j.plugins) for(const k of Object.keys(j.plugins)) console.log(k);
    }catch(e){}
  ' "$MACHINE_PLUGINS_DIR/installed_plugins.json" 2>/dev/null
}

# Manifest marketplaces as "name<TAB>repo".
manifest_marketplaces() {
  have_node || return 0
  [ -f "$PLUGIN_MANIFEST" ] || return 0
  node -e '
    const fs=require("fs");
    try{const j=JSON.parse((x=>x.charCodeAt(0)===65279?x.slice(1):x)(fs.readFileSync(process.argv[1],"utf8")));
      if(j.marketplaces) for(const [n,r] of Object.entries(j.marketplaces)) console.log(n+"\t"+r);
    }catch(e){}
  ' "$PLUGIN_MANIFEST" 2>/dev/null
}

# Manifest plugin names, one per line.
manifest_plugins() {
  have_node || return 0
  [ -f "$PLUGIN_MANIFEST" ] || return 0
  node -e '
    const fs=require("fs");
    try{const j=JSON.parse((x=>x.charCodeAt(0)===65279?x.slice(1):x)(fs.readFileSync(process.argv[1],"utf8")));
      if(Array.isArray(j.plugins)) for(const p of j.plugins) console.log(p);
    }catch(e){}
  ' "$PLUGIN_MANIFEST" 2>/dev/null
}

# ── Harvest mode: regenerate plugins.json from this machine's live plugin state ──
# A marketplace is kept if it's non-default OR a listed plugin depends on it. Mirrors
# setup.ps1 -HarvestPlugins. Runs before anything else and exits.
if [ "$HARVEST_PLUGINS" -eq 1 ]; then
  if ! have_node; then
    sayc "$C_RED" "node is required to harvest plugins (parses the plugin state JSON). Install Node.js and re-run."
    exit 1
  fi
  node -e '
    const fs=require("fs");
    const [km,ip,out,defaultsCsv]=process.argv.slice(1);
    const defaults=defaultsCsv.split(",").filter(Boolean);
    let mkts={},plugins=[];
    try{const j=JSON.parse(fs.readFileSync(km,"utf8"));
      for(const [n,v] of Object.entries(j)){ if(v&&v.source&&v.source.source==="github"&&v.source.repo) mkts[n]=v.source.repo; }
    }catch(e){}
    try{const j=JSON.parse(fs.readFileSync(ip,"utf8"));
      if(j.plugins) plugins=Object.keys(j.plugins);
    }catch(e){}
    const referenced=new Set(plugins.map(p=>p.split("@").pop()));
    const kept=Object.keys(mkts).filter(n=>!defaults.includes(n)||referenced.has(n)).sort();
    const outM={}; for(const n of kept) outM[n]=mkts[n];
    const manifest={marketplaces:outM,plugins:plugins.slice().sort()};
    fs.writeFileSync(out, JSON.stringify(manifest,null,4)+"\n");
  ' "$MACHINE_PLUGINS_DIR/known_marketplaces.json" "$MACHINE_PLUGINS_DIR/installed_plugins.json" "$PLUGIN_MANIFEST" "$DEFAULT_MARKETPLACES"
  sayc "$C_CYAN" "Regenerated plugin manifest -> $PLUGIN_MANIFEST"
  mk=$(manifest_marketplaces | cut -f1 | paste -sd', ' -); [ -z "$mk" ] && mk="(none)"
  pl=$(manifest_plugins | paste -sd', ' -);              [ -z "$pl" ] && pl="(none)"
  say  "  marketplaces: $mk"
  say  "  plugins     : $pl"
  say  ""
  sayc "$C_YELLOW" "Review, then commit & push to record these in cc-toolkit."
  exit 0
fi

# ── Detect an existing Claude Code config ───────────────────────────
existing=0
if [ -d "$CLAUDE_HOME" ]; then
  for item in "${TOOLKIT_ITEMS[@]}"; do
    if [ -e "$CLAUDE_HOME/$item" ]; then existing=1; break; fi
  done
fi

# ── EXISTING CONFIG + no --force: audit + harvest report, change nothing ──
if [ "$existing" -eq 1 ] && [ "$FORCE" -eq 0 ]; then
  sayc "$C_YELLOW" "Existing Claude Code config detected at $CLAUDE_HOME"
  sayc "$C_YELLOW" "AUDIT MODE - nothing will be changed. Reviewing differences..."
  say ""

  conflicts=(); additions=(); harvest=(); insync=0

  # repo -> machine (what cc-toolkit would add or change)
  for item in "${TOOLKIT_ITEMS[@]}"; do
    while IFS=$'\t' read -r rel full; do
      [ -z "$rel" ] && continue
      dest="$CLAUDE_HOME/$rel"
      if [ ! -e "$dest" ]; then
        additions+=("$rel")
      elif [ "$(hash_file "$full")" != "$(hash_file "$dest")" ]; then
        conflicts+=("$rel")
      else
        insync=$((insync + 1))
      fi
    done < <(list_item_files "$REPO_ROOT" "$item")
  done

  # machine -> repo (machine-unique = harvest candidates)
  for item in "${TOOLKIT_ITEMS[@]}"; do
    while IFS=$'\t' read -r rel full; do
      [ -z "$rel" ] && continue
      [ ! -e "$REPO_ROOT/$rel" ] && harvest+=("$rel")
    done < <(list_item_files "$CLAUDE_HOME" "$item")
  done

  say "  In sync (identical): $insync file(s)"
  say ""
  if [ "${#conflicts[@]}" -gt 0 ]; then
    sayc "$C_RED" "  CONFLICTS - this machine differs from cc-toolkit (review before overwriting):"
    for c in "${conflicts[@]}"; do sayc "$C_RED" "    ~ $c"; done
    say ""
  fi
  if [ "${#harvest[@]}" -gt 0 ]; then
    sayc "$C_MAGENTA" "  HARVEST CANDIDATES - present here, NOT in cc-toolkit (pull these UP first):"
    for h in "${harvest[@]}"; do sayc "$C_MAGENTA" "    + $h"; done
    say ""
  fi
  if [ "${#additions[@]}" -gt 0 ]; then
    sayc "$C_GREEN" "  WOULD BE ADDED from cc-toolkit (new on this machine):"
    for a in "${additions[@]}"; do sayc "$C_GREEN" "    > $a"; done
    say ""
  fi

  # plugins: declarative intent comparison (manifest vs machine), not a byte diff
  machine_pl="$(machine_plugins)"
  manifest_pl="$(manifest_plugins)"
  plugin_harvest=""
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    printf '%s\n' "$manifest_pl" | grep -qxF "$p" || plugin_harvest+="$p"$'\n'
  done <<< "$machine_pl"
  plugin_install=""
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    printf '%s\n' "$machine_pl" | grep -qxF "$p" || plugin_install+="$p"$'\n'
  done <<< "$manifest_pl"
  if [ -n "${plugin_harvest//[$'\n']/}" ]; then
    sayc "$C_MAGENTA" "  HARVEST CANDIDATES (plugins) - installed here, NOT in plugins.json:"
    while IFS= read -r p; do [ -n "$p" ] && sayc "$C_MAGENTA" "    + plugin: $p"; done <<< "$plugin_harvest"
    sayc "$C_MAGENTA" "    -> run: bash deployment/unix/setup.sh --harvest-plugins  (regenerates plugins.json)"
    say ""
  fi
  if [ -n "${plugin_install//[$'\n']/}" ]; then
    sayc "$C_GREEN" "  WOULD BE INSTALLED from plugins.json (not yet on this machine):"
    while IFS= read -r p; do [ -n "$p" ] && sayc "$C_GREEN" "    > plugin: $p"; done <<< "$plugin_install"
    say ""
  fi

  sayc "$C_CYAN" "Next steps:"
  say "  1. HARVEST  - copy anything above worth keeping into the cc-toolkit repo, commit & push."
  say "               (for plugins: run --harvest-plugins to regenerate plugins.json, then commit & push.)"
  say "  2. REVIEW   - decide whether cc-toolkit's version should win on each CONFLICT."
  say "  3. DEPLOY   - re-run with --force to install (a backup is taken first)."
  say ""
  sayc "$C_YELLOW" "No changes were made."
  exit 0
fi

# ── Lightweight backup of exactly the toolkit files we may overwrite ─
mkdir -p "$CLAUDE_HOME"
stamp="$(date +%Y%m%d-%H%M%S)"
backup="$CLAUDE_HOME.backup-$stamp"
backed_up=0
for item in "${TOOLKIT_ITEMS[@]}"; do
  p="$CLAUDE_HOME/$item"
  if [ -e "$p" ]; then
    mkdir -p "$backup"
    cp -R "$p" "$backup/$item"
    backed_up=1
  fi
done
[ "$backed_up" -eq 1 ] && sayc "$C_CYAN" "Backed up existing toolkit files -> $backup"

# ── Deploy toolkit items (merge dirs; never secrets) ────────────────
for item in "${TOOLKIT_ITEMS[@]}"; do
  src="$REPO_ROOT/$item"
  [ -e "$src" ] || continue
  dst="$CLAUDE_HOME/$item"
  if [ -f "$src" ]; then
    cp -f "$src" "$dst"
  else
    mkdir -p "$dst"
    cp -R "$src/." "$dst/"
  fi
  sayc "$C_GREEN" "  deployed: $item"
done

# Defensive: warn if a secret ever ended up in the repo (should be impossible).
for secret in "${NEVER_TOUCH[@]}"; do
  if [ -e "$REPO_ROOT/$secret" ]; then
    sayc "$C_RED" "  WARNING: $secret exists in the repo - it must never be committed."
  fi
done

# ── Hydrate plugins from the declarative manifest (marketplace add + install) ──
# Re-creates plugins/ from intent; never version-controlled. Idempotent (re-adding a
# marketplace or re-installing a plugin is a no-op). Tolerant of offline / missing 'claude'
# - degrades to printing the commands to run by hand.
mkts_out="$(manifest_marketplaces)"
plugins_out="$(manifest_plugins)"
if [ -n "$mkts_out" ] || [ -n "$plugins_out" ]; then
  if command -v claude >/dev/null 2>&1; then
    say ""
    sayc "$C_CYAN" "Hydrating plugins from plugins.json..."
    while IFS=$'\t' read -r name repo; do
      [ -z "$name" ] && continue
      if claude plugin marketplace add "$repo" >/dev/null 2>&1; then
        sayc "$C_GREEN" "  marketplace: $name ($repo)"
      else
        sayc "$C_YELLOW" "  [note] marketplace '$name' add returned nonzero (may already exist) - continuing"
      fi
    done <<< "$mkts_out"
    while IFS= read -r p; do
      [ -z "$p" ] && continue
      if claude plugin install "$p" --scope user >/dev/null 2>&1; then
        sayc "$C_GREEN" "  installed: $p"
      else
        sayc "$C_YELLOW" "  [note] plugin '$p' install returned nonzero (may already be installed) - continuing"
      fi
    done <<< "$plugins_out"
  else
    say ""
    sayc "$C_YELLOW" "Plugins not hydrated - 'claude' not on PATH yet. After install, run:"
    while IFS=$'\t' read -r name repo; do [ -n "$name" ] && say "  claude plugin marketplace add $repo"; done <<< "$mkts_out"
    while IFS= read -r p; do [ -n "$p" ] && say "  claude plugin install $p --scope user"; done <<< "$plugins_out"
  fi
fi

say ""
sayc "$C_GREEN" "Toolkit deployed to $CLAUDE_HOME"
sayc "$C_CYAN" "Next:"
say '  export ANTHROPIC_API_KEY="sk-ant-..."   # from your password manager'
say "  claude"
say ""
