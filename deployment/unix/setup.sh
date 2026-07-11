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
# Usage:
#   ./setup.sh            # clean machine -> deploy; existing config -> audit only
#   ./setup.sh --force    # deploy over an existing config (backup taken first)
#
set -euo pipefail

# ── Args ────────────────────────────────────────────────────────────
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force|-f|-Force) FORCE=1 ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^#\{0,1\} \{0,1\}//'
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

  sayc "$C_CYAN" "Next steps:"
  say "  1. HARVEST  - copy anything above worth keeping into the cc-toolkit repo, commit & push."
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

say ""
sayc "$C_GREEN" "Toolkit deployed to $CLAUDE_HOME"
sayc "$C_CYAN" "Next:"
say '  export ANTHROPIC_API_KEY="sk-ant-..."   # from your password manager'
say "  claude"
say ""
