#!/usr/bin/env bash
#
# Clean exit: remove the GKT toolkit (and all of ~/.claude) from this machine and
# unset the API key. Linux / macOS counterpart of deployment/windows/cleanup.ps1.
#
# Safe by default (mirrors setup.sh / cleanup.ps1):
#   - No flags: DRY RUN. Reports what would be removed and the API-key state. Changes nothing.
#   - --force: removes ~/.claude and clears ANTHROPIC_API_KEY from ~/.bashrc/~/.zshrc.
#     A timestamped backup is taken first UNLESS --no-backup is given.
#   - --force --no-backup: true client-exit. No backup left behind. Removes the whole
#     ~/.claude — config, secrets, AND session history (may hold the client's sensitive
#     prompts) — so nothing of yours remains.
#
# NOTE ON THE API KEY: a child process cannot unset a variable in your current shell.
# This script removes any persisted `export ANTHROPIC_API_KEY=...` line from your shell
# rc files and tells you to run `unset ANTHROPIC_API_KEY` (or open a new shell) to clear
# it from the live session. Run as `source cleanup.sh --force` to also unset it here.
#
# Usage:
#   ./cleanup.sh                    # dry run
#   ./cleanup.sh --force            # remove, backup to ~/.claude.backup-cleanup-<ts> first
#   ./cleanup.sh --force --no-backup # client exit - remove everything, leave no backup
#
set -euo pipefail

FORCE=0
NO_BACKUP=0
for arg in "$@"; do
  case "$arg" in
    --force|-f)     FORCE=1 ;;
    --no-backup)    NO_BACKUP=1 ;;
    -h|--help)      sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^#\{0,1\} \{0,1\}//'; return 0 2>/dev/null || exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; return 2 2>/dev/null || exit 2 ;;
  esac
done

if [ -t 1 ]; then
  C_CYAN=$'\033[36m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_RESET=$'\033[0m'
else
  C_CYAN=; C_GREEN=; C_YELLOW=; C_RED=; C_RESET=
fi
say()  { printf '%s\n' "$*"; }
sayc() { printf '%s%s%s\n' "$1" "$2" "$C_RESET"; }

CLAUDE_HOME="$HOME/.claude"
KEY_NAME="ANTHROPIC_API_KEY"
RC_FILES=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")

say ""
sayc "$C_CYAN" "GKT cc-toolkit cleanup"
say  "  target : $CLAUDE_HOME"
say ""

home_exists=0; [ -d "$CLAUDE_HOME" ] && home_exists=1
key_live=0;    [ -n "${ANTHROPIC_API_KEY:-}" ] && key_live=1

# which rc files persist the key
rc_hits=()
for rc in "${RC_FILES[@]}"; do
  [ -f "$rc" ] && grep -q "$KEY_NAME" "$rc" 2>/dev/null && rc_hits+=("$rc")
done

# ── DRY RUN ─────────────────────────────────────────────────────────
if [ "$FORCE" -eq 0 ]; then
  sayc "$C_YELLOW" "DRY RUN - nothing will be changed."
  say ""
  if [ "$home_exists" -eq 1 ]; then
    count=$(find "$CLAUDE_HOME" -type f 2>/dev/null | wc -l | tr -d ' ')
    sayc "$C_RED" "  WOULD REMOVE  ~/.claude  ($count file(s), incl. config, secrets, session history)"
  else
    sayc "$C_GREEN" "  ~/.claude does not exist - nothing to remove."
  fi
  say ""
  say "  API key ($KEY_NAME):"
  say  "    live shell : $([ "$key_live" -eq 1 ] && echo 'set - clear with: unset ANTHROPIC_API_KEY' || echo 'not set')"
  if [ "${#rc_hits[@]}" -gt 0 ]; then
    sayc "$C_RED" "    persisted  : found in ${rc_hits[*]} - WOULD be removed"
  else
    say "    persisted  : not found in shell rc files"
  fi
  say ""
  sayc "$C_CYAN" "To actually clean:"
  say "  ./cleanup.sh --force              # backs up to ~/.claude.backup-cleanup-<ts> first"
  say "  ./cleanup.sh --force --no-backup  # client exit - leaves no backup behind"
  say ""
  return 0 2>/dev/null || exit 0
fi

# ── FORCE: back up (unless --no-backup), then remove ────────────────
if [ "$home_exists" -eq 1 ]; then
  if [ "$NO_BACKUP" -eq 0 ]; then
    stamp="$(date +%Y%m%d-%H%M%S)"
    backup="$CLAUDE_HOME.backup-cleanup-$stamp"
    cp -R "$CLAUDE_HOME" "$backup"
    sayc "$C_CYAN" "Backed up ~/.claude -> $backup"
  else
    sayc "$C_YELLOW" "No backup taken (--no-backup) - removal is permanent."
  fi
  rm -rf "$CLAUDE_HOME"
  sayc "$C_GREEN" "  removed: ~/.claude"
else
  sayc "$C_GREEN" "  ~/.claude already absent - nothing to remove."
fi

# ── Strip persisted key from rc files ───────────────────────────────
for rc in "${rc_hits[@]}"; do
  cp "$rc" "$rc.bak-cleanup"
  grep -v "$KEY_NAME" "$rc.bak-cleanup" > "$rc"
  sayc "$C_GREEN" "  cleaned: $KEY_NAME line removed from $rc (backup: $rc.bak-cleanup)"
done

# ── Unset in the live shell if sourced ──────────────────────────────
if [ "$key_live" -eq 1 ]; then
  unset ANTHROPIC_API_KEY 2>/dev/null \
    && sayc "$C_GREEN" "  unset: $KEY_NAME (this shell)" \
    || sayc "$C_YELLOW" "  $KEY_NAME still set in your live shell - run: unset ANTHROPIC_API_KEY (or open a new shell)"
fi

say ""
if [ ! -d "$CLAUDE_HOME" ]; then
  sayc "$C_GREEN" "Clean. ~/.claude removed. Confirm the key is gone with: echo \$ANTHROPIC_API_KEY"
else
  sayc "$C_RED" "WARNING: $CLAUDE_HOME still present."
fi
say ""
