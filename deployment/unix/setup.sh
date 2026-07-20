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
#   the audit reports real drift only. settings.json is compared *semantically* (a
#   canonical-JSON hash with runtime keys stripped - see SETTINGS_RUNTIME_KEYS below) so
#   plugin-hydration churn and the model/effortLevel runtime fields never register as drift.
#
# Plugins (parity with setup.ps1): Claude Code plugins live in ~/.claude/plugins/, which is
# self-updating, machine-path-laden runtime state (gitignored). We version the *intent* in
# plugins.json (marketplaces + plugin names) and re-hydrate the bytes on deploy via the
# claude CLI. JSON is parsed with node (a guaranteed prerequisite), so no jq dependency.
#
# --harvest is the inverse of deploy, for FILES: lists toolkit files on this machine but not
# in the repo (NEW-UP) or edited here and newer than the repo (CHANGED-UP). Dry-run by
# default; add --force to copy them into the repo working tree. Never harvests secrets.
#
# --check is a fast, silent, once-per-day drift verdict meant for a SessionStart hook: prints
# one line if local files aren't yet harvested, otherwise nothing. Side-effect-free.
#
# CC_TOOLKIT_HOME anchor: every deploy writes this script's resolved repo path to
# ~/.claude/.cc-toolkit-home (a marker file, not a shell-rc export, so it doesn't depend on
# which shell re-sources what). Nothing on Unix reads it yet - there is no drift-check.sh /
# hook wiring here, unlike Windows - but it's the anchor a future one needs.
#
# Usage:
#   ./setup.sh                   # clean machine -> deploy; existing config -> audit only
#   ./setup.sh --force           # deploy over an existing config (backup taken first)
#   ./setup.sh --harvest-plugins # regenerate plugins.json from installed plugins, then stop
#   ./setup.sh --harvest         # list local toolkit files not yet in the repo (dry-run)
#   ./setup.sh --harvest --force # copy those files UP into the repo, then commit & push
#   ./setup.sh --check           # one-line drift verdict (for a SessionStart hook)
#
set -euo pipefail

# ── Args ────────────────────────────────────────────────────────────
FORCE=0
HARVEST_PLUGINS=0
HARVEST=0
CHECK=0
for arg in "$@"; do
  case "$arg" in
    --force|-f|-Force) FORCE=1 ;;
    --harvest-plugins|-HarvestPlugins) HARVEST_PLUGINS=1 ;;
    --harvest|-Harvest) HARVEST=1 ;;
    --check|-Check) CHECK=1 ;;
    -h|--help)
      # Print the header comment (lines 2 through, not including, 'set -euo pipefail') -
      # robust to the header growing/shrinking, unlike a hardcoded line range.
      awk '/^set -euo pipefail/{exit} NR>1{print}' "$0" | sed 's/^#\{0,1\} \{0,1\}//'
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

# Banner + prerequisite checks: skipped for --check (must be silent + side-effect-free,
# since it runs from a SessionStart hook on every launch).
if [ "$CHECK" -eq 0 ]; then

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

fi  # end (CHECK == 0) banner + prerequisite guard

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

# ── Cross-platform mtime (GNU stat vs BSD/macOS stat) ────────────────
stat_mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null; }

# ── Canonical-JSON compare for settings.json (mirrors setup.ps1) ─────────────────────
# settings.json drifts after every deploy/session: plugin hydration appends
# enabledPlugins/extraKnownMarketplaces, and /model + the effort toggle rewrite
# model/effortLevel locally every session. Strip those runtime keys, sort object keys
# recursively, hash the canonical form - so only real content changes register as drift.
# Keep SETTINGS_RUNTIME_KEYS in sync with setup.ps1's $SettingsRuntimeKeys.
settings_canonical_json() {
  have_node || return 1
  node -e '
    const fs = require("fs");
    const SETTINGS_RUNTIME_KEYS = ["enabledPlugins", "extraKnownMarketplaces", "model", "effortLevel"];
    function canon(o) {
      if (Array.isArray(o)) return o.map(canon);
      if (o && typeof o === "object") {
        const out = {};
        for (const k of Object.keys(o).sort()) out[k] = canon(o[k]);
        return out;
      }
      return o;
    }
    try {
      const j = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
      for (const k of SETTINGS_RUNTIME_KEYS) delete j[k];
      process.stdout.write(JSON.stringify(canon(j)));
    } catch (e) { process.exit(1); }
  ' "$1" 2>/dev/null
}

# Route settings.json through the canonical-JSON hash; everything else uses the raw content
# hash. Falls back to the raw hash if node is missing or the file fails to parse.
compare_hash() {
  local rel="$1" path="$2" canon
  if [ "$rel" = "settings.json" ] && canon="$(settings_canonical_json "$path")" && [ -n "$canon" ]; then
    printf '%s' "$canon" | sha_sum
  else
    hash_file "$path"
  fi
}

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

# ── Classify drift between this machine (~/.claude) and the repo, per toolkit file ────
# Shared by the audit, --harvest, and --check so all three agree. Content-hash is
# authoritative for "differs"; direction (local/repo newer) is a HINT from mtime and can
# mislead right after a fresh 'git clone' (which resets mtimes).
#   harvest UP  = new-local + local-newer      deploy DOWN = new-repo + repo-newer
# Populates the DRIFT_* globals; callers read those after calling this.
compute_drift() {
  # Suspended for the whole function, not just risky lines: this is a pure read-only
  # comparison (nothing here mutates state), and it is built entirely out of
  # naturally-nonzero comparisons/tests feeding nested pipelines and process substitutions
  # (find | while read, command substitutions inside if/elif). set -e's exemptions for
  # AND-OR lists and loop conditions do not reliably cover every nesting here across bash
  # implementations - suspend it for the duration rather than chase exit-status edge cases.
  set +e
  DRIFT_INSYNC=0
  DRIFT_LOCAL_NEWER=()
  DRIFT_REPO_NEWER=()
  DRIFT_NEW_LOCAL=()
  DRIFT_NEW_REPO=()

  local item rel full dest repo_time loc_time
  for item in "${TOOLKIT_ITEMS[@]}"; do
    while IFS=$'\t' read -r rel full; do
      [ -z "$rel" ] && continue
      dest="$CLAUDE_HOME/$rel"
      if [ ! -e "$dest" ]; then
        DRIFT_NEW_REPO+=("$rel")
      elif [ "$(compare_hash "$rel" "$full")" != "$(compare_hash "$rel" "$dest")" ]; then
        repo_time="$(stat_mtime "$full")"
        loc_time="$(stat_mtime "$dest")"
        if [ -n "$loc_time" ] && [ -n "$repo_time" ] && [ "$loc_time" -gt "$repo_time" ]; then
          DRIFT_LOCAL_NEWER+=("$rel")
        else
          DRIFT_REPO_NEWER+=("$rel")
        fi
      else
        DRIFT_INSYNC=$((DRIFT_INSYNC + 1))
      fi
    done < <(list_item_files "$REPO_ROOT" "$item")
  done

  for item in "${TOOLKIT_ITEMS[@]}"; do
    while IFS=$'\t' read -r rel full; do
      [ -z "$rel" ] && continue
      [ ! -e "$REPO_ROOT/$rel" ] && DRIFT_NEW_LOCAL+=("$rel")
    done < <(list_item_files "$CLAUDE_HOME" "$item")
  done
  set -e
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

# ── Harvest mode (files): pull machine-side toolkit files UP into the repo ────────
# The inverse of deploy. Lists machine-unique (NEW-UP) + machine-newer (CHANGED-UP)
# toolkit files; with --force, copies them into the repo working tree for you to review,
# commit & push. Dry-run otherwise. Never harvests secrets.
if [ "$HARVEST" -eq 1 ]; then
  if [ ! -d "$CLAUDE_HOME" ]; then
    sayc "$C_YELLOW" "No $CLAUDE_HOME found - nothing to harvest."
    exit 0
  fi
  compute_drift

  if [ "${#DRIFT_NEW_LOCAL[@]}" -eq 0 ] && [ "${#DRIFT_LOCAL_NEWER[@]}" -eq 0 ]; then
    sayc "$C_GREEN" "Nothing to harvest - the repo already has this machine's toolkit files."
    if [ "${#DRIFT_REPO_NEWER[@]}" -gt 0 ]; then
      sayc "$C_YELLOW" "  (Note: ${#DRIFT_REPO_NEWER[@]} file(s) are NEWER in the repo - deploy DOWN with --force.)"
    fi
    exit 0
  fi

  sayc "$C_MAGENTA" "Harvest candidates (this machine -> repo):"
  if [ "${#DRIFT_NEW_LOCAL[@]}" -gt 0 ]; then
    sayc "$C_MAGENTA" "  NEW-UP (here, not in the repo):"
    for f in "${DRIFT_NEW_LOCAL[@]}"; do sayc "$C_MAGENTA" "    + $f"; done
  fi
  if [ "${#DRIFT_LOCAL_NEWER[@]}" -gt 0 ]; then
    sayc "$C_MAGENTA" "  CHANGED-UP (edited here, newer than the repo):"
    for f in "${DRIFT_LOCAL_NEWER[@]}"; do sayc "$C_MAGENTA" "    ^ $f"; done
  fi
  if [ "${#DRIFT_REPO_NEWER[@]}" -gt 0 ]; then
    sayc "$C_YELLOW" "  SKIPPED - repo is newer (deploy DOWN instead, do not harvest):"
    for f in "${DRIFT_REPO_NEWER[@]}"; do sayc "$C_YELLOW" "    v $f"; done
  fi
  say ""

  if [ "$FORCE" -eq 0 ]; then
    sayc "$C_YELLOW" "DRY RUN - nothing copied. Re-run with --force to copy the above UP into the repo."
    exit 0
  fi

  copied=0
  for rel in "${DRIFT_NEW_LOCAL[@]}" "${DRIFT_LOCAL_NEWER[@]}"; do
    skip=0
    for nt in "${NEVER_TOUCH[@]}"; do [ "$rel" = "$nt" ] && skip=1; done
    [ "$skip" -eq 1 ] && continue
    src="$CLAUDE_HOME/$rel"
    dst="$REPO_ROOT/$rel"
    mkdir -p "$(dirname "$dst")"
    cp -f "$src" "$dst"
    sayc "$C_GREEN" "  harvested: $rel"
    copied=$((copied + 1))
  done
  say ""
  sayc "$C_GREEN" "Harvested $copied file(s) into $REPO_ROOT"
  sayc "$C_YELLOW" "Review, then commit & push to record them in cc-toolkit."
  exit 0
fi

# ── Check mode: fast, throttled drift verdict for a SessionStart hook ─────────────
# Prints ONE line to stdout (so a hook captures it) and exits. Throttled to once/day via a
# marker file so it adds no latency to repeated session starts. Errors are swallowed - a
# hook must never break a session start. Nothing on Unix invokes this today (no
# drift-check.sh / hook wiring exists yet), but it's ready to be called once that lands.
if [ "$CHECK" -eq 1 ]; then
  set +e
  if [ -d "$CLAUDE_HOME" ]; then
    marker="$CLAUDE_HOME/.toolkit-drift-check"
    run_check=1
    if [ -f "$marker" ]; then
      marker_time="$(stat_mtime "$marker" 2>/dev/null)"
      now="$(date +%s)"
      if [ -n "$marker_time" ] && [ $((now - marker_time)) -lt 86400 ]; then
        run_check=0
      fi
    fi
    if [ "$run_check" -eq 1 ]; then
      compute_drift
      up=$(( ${#DRIFT_NEW_LOCAL[@]} + ${#DRIFT_LOCAL_NEWER[@]} ))
      if [ "$up" -gt 0 ]; then
        echo "cc-toolkit: $up local file(s) not yet harvested -> run: setup.sh --harvest"
      fi
      date -u +%Y-%m-%dT%H:%M:%SZ > "$marker" 2>/dev/null
    fi
  fi
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

  compute_drift

  say "  In sync (identical): $DRIFT_INSYNC file(s)"
  say ""
  # Direction (LOCAL/REPO newer) is a HINT from mtime; the content-hash is authoritative for
  # "differs". A fresh 'git clone' resets mtimes, so on a just-cloned machine treat REPO NEWER
  # with care.
  if [ "${#DRIFT_LOCAL_NEWER[@]}" -gt 0 ]; then
    sayc "$C_MAGENTA" "  LOCAL NEWER - edited here, newer than cc-toolkit (harvest UP):"
    for f in "${DRIFT_LOCAL_NEWER[@]}"; do sayc "$C_MAGENTA" "    ^ $f"; done
    say ""
  fi
  if [ "${#DRIFT_NEW_LOCAL[@]}" -gt 0 ]; then
    sayc "$C_MAGENTA" "  HARVEST CANDIDATES - present here, NOT in cc-toolkit (harvest UP):"
    for f in "${DRIFT_NEW_LOCAL[@]}"; do sayc "$C_MAGENTA" "    + $f"; done
    say ""
  fi
  if [ "${#DRIFT_REPO_NEWER[@]}" -gt 0 ]; then
    sayc "$C_RED" "  REPO NEWER - cc-toolkit differs and is newer (deploy DOWN with --force):"
    for f in "${DRIFT_REPO_NEWER[@]}"; do sayc "$C_RED" "    v $f"; done
    say ""
  fi
  if [ "${#DRIFT_NEW_REPO[@]}" -gt 0 ]; then
    sayc "$C_GREEN" "  WOULD BE ADDED from cc-toolkit (new on this machine):"
    for f in "${DRIFT_NEW_REPO[@]}"; do sayc "$C_GREEN" "    > $f"; done
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
  say "  1. HARVEST UP - LOCAL NEWER + HARVEST CANDIDATES are local work not yet in cc-toolkit."
  say "                  Run: ./deployment/unix/setup.sh --harvest   (dry-run; add --force to copy up)"
  say "                  (plugins: --harvest-plugins regenerates plugins.json.) Then commit & push."
  say "  2. DEPLOY DOWN - REPO NEWER + WOULD BE ADDED come from cc-toolkit; re-run with --force to"
  say "                  install them here (a backup is taken first)."
  say ""
  sayc "$C_YELLOW" "No changes were made."
  exit 0
fi

# ── Lightweight backup of exactly the toolkit files we may overwrite ─
mkdir -p "$CLAUDE_HOME"
stamp="$(date +%Y%m%d-%H%M%S)"
backup="$HOME/.claude backups/$stamp"
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

# ── Persist the repo anchor ────────────────────────────────────────
# A marker file (not a shell-rc export) lets a future drift-check.sh or Unix invocation of
# s.ship-cc-tlkit locate this clone without a hardcoded path or depending on which shell
# re-sources what. Mirrors setup.ps1's CC_TOOLKIT_HOME (a User-scope env var there) - same
# anchor role, Unix-appropriate mechanism. No-op when already correct.
anchor_file="$CLAUDE_HOME/.cc-toolkit-home"
if [ ! -f "$anchor_file" ] || [ "$(cat "$anchor_file" 2>/dev/null)" != "$REPO_ROOT" ]; then
  printf '%s\n' "$REPO_ROOT" > "$anchor_file"
  sayc "$C_GREEN" "  set anchor -> $anchor_file ($REPO_ROOT)"
fi
export CC_TOOLKIT_HOME="$REPO_ROOT"

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
