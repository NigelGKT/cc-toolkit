# cc-toolkit drift check — deployed to ~/.claude, invoked by the SessionStart hook
# (see settings.json). Delegates to the repo's setup.ps1 -Check when CC_TOOLKIT_HOME
# points at a cc-toolkit clone; no-ops silently otherwise (opt-in per machine).
#
# Why a -File wrapper instead of an inline -Command in the hook: -File takes no inline
# variables, so the check behaves the same regardless of how the harness shell quotes or
# expands the hook command string. Mirrors the proven `node ~/.claude/statusline.js` pattern.
# Resolve the anchor. The process env alone is unreliable: a session inherits its environment at
# launch, so $env:CC_TOOLKIT_HOME is empty in any session that started without it - which silently
# no-ops this hook even on a machine where the variable IS set (observed 2026-07-17: User scope had
# the path, the running session's env did not). Fall back to the persisted scopes.
$repo = $env:CC_TOOLKIT_HOME
if (-not $repo) { $repo = [Environment]::GetEnvironmentVariable('CC_TOOLKIT_HOME', 'User') }
if (-not $repo) { $repo = [Environment]::GetEnvironmentVariable('CC_TOOLKIT_HOME', 'Machine') }
if (-not $repo) { return }
$setup = Join-Path $repo 'deployment/windows/setup.ps1'
if (Test-Path $setup) { & $setup -Check }
