# cc-toolkit drift check — deployed to ~/.claude, invoked by the SessionStart hook
# (see settings.json). Delegates to the repo's setup.ps1 -Check when CC_TOOLKIT_HOME
# points at a cc-toolkit clone; no-ops silently otherwise (opt-in per machine).
#
# Why a -File wrapper instead of an inline -Command in the hook: -File takes no inline
# variables, so the check behaves the same regardless of how the harness shell quotes or
# expands the hook command string. Mirrors the proven `node ~/.claude/statusline.js` pattern.
$repo = $env:CC_TOOLKIT_HOME
if (-not $repo) { return }
$setup = Join-Path $repo 'deployment/windows/setup.ps1'
if (Test-Path $setup) { & $setup -Check }
