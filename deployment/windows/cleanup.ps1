<#
.SYNOPSIS
  Clean exit: remove the GKT toolkit (and all of ~/.claude) from this machine and
  unset the API key. For handing a client machine back with nothing of yours left.

.DESCRIPTION
  Safe by default (mirrors setup.ps1).
  - No flags: DRY RUN. Reports exactly what would be removed and the API-key state.
    Changes nothing.
  - -Force: actually removes ~/.claude and unsets ANTHROPIC_API_KEY (process + User
    scope). A timestamped backup is taken first UNLESS -NoBackup is given.
  - -Force -NoBackup: true client-exit. No backup is left on the machine. Removes the
    whole ~/.claude — config, secrets, AND session history (which can hold the client's
    sensitive prompts) — so nothing of yours remains.

  Why the whole directory: a professional hand-back must leave no config, no stored
  credentials, and no transcript of the work. Removing ~/.claude achieves all three;
  Claude Code recreates a fresh empty one on next launch.

.PARAMETER Force
  Perform the removal. Without it, the script only reports.

.PARAMETER NoBackup
  Skip the pre-removal backup. Use on a client machine so no residue is left behind.

.EXAMPLE
  .\cleanup.ps1                 # dry run - shows what would be removed
  .\cleanup.ps1 -Force          # remove, but back up to ~/.claude.backup-cleanup-<ts> first
  .\cleanup.ps1 -Force -NoBackup # client exit - remove everything, leave no backup
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$NoBackup
)

$ErrorActionPreference = 'Stop'

$ClaudeHome = Join-Path $env:USERPROFILE '.claude'
$KeyName    = 'ANTHROPIC_API_KEY'

Write-Host ""
Write-Host "GKT cc-toolkit cleanup" -ForegroundColor Cyan
Write-Host "  target : $ClaudeHome"
Write-Host ""

# ── Inspect current state ───────────────────────────────────────────
$homeExists = Test-Path $ClaudeHome
$keyProcess = [bool]$env:ANTHROPIC_API_KEY
$keyUser    = [bool][Environment]::GetEnvironmentVariable($KeyName, 'User')

# ── DRY RUN (no -Force): report only, change nothing ────────────────
if (-not $Force) {
    Write-Host "DRY RUN - nothing will be changed." -ForegroundColor Yellow
    Write-Host ""
    if ($homeExists) {
        $count = (Get-ChildItem -Path $ClaudeHome -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Host "  WOULD REMOVE  ~/.claude  ($count file(s), incl. config, secrets, session history)" -ForegroundColor Red
    } else {
        Write-Host "  ~/.claude does not exist - nothing to remove." -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "  API key ($KeyName):"
    Write-Host ("    process scope : {0}" -f ($(if ($keyProcess) { 'set - WOULD be cleared' } else { 'not set' })))
    Write-Host ("    User scope    : {0}" -f ($(if ($keyUser)    { 'set - WOULD be cleared' } else { 'not set' })))
    Write-Host ""
    Write-Host "To actually clean:" -ForegroundColor Cyan
    Write-Host "  .\cleanup.ps1 -Force            # backs up to ~/.claude.backup-cleanup-<ts> first"
    Write-Host "  .\cleanup.ps1 -Force -NoBackup  # client exit - leaves no backup behind"
    Write-Host ""
    return
}

# ── FORCE: back up (unless -NoBackup), then remove ──────────────────
if ($homeExists) {
    if (-not $NoBackup) {
        $stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backup = "$ClaudeHome.backup-cleanup-$stamp"
        Copy-Item -Path $ClaudeHome -Destination $backup -Recurse -Force
        Write-Host "Backed up ~/.claude -> $backup" -ForegroundColor Cyan
    } else {
        Write-Host "No backup taken (-NoBackup) - removal is permanent." -ForegroundColor Yellow
    }
    Remove-Item -Path $ClaudeHome -Recurse -Force
    Write-Host "  removed: ~/.claude" -ForegroundColor Green
} else {
    Write-Host "  ~/.claude already absent - nothing to remove." -ForegroundColor Green
}

# ── Unset the API key (process + persisted User scope) ──────────────
if ($keyProcess) {
    Remove-Item Env:$KeyName -ErrorAction SilentlyContinue
    Write-Host "  unset: $KeyName (process scope)" -ForegroundColor Green
}
if ($keyUser) {
    [Environment]::SetEnvironmentVariable($KeyName, $null, 'User')
    Write-Host "  unset: $KeyName (User scope - persisted)" -ForegroundColor Green
}

# ── Verify + report ─────────────────────────────────────────────────
Write-Host ""
$stillThere = Test-Path $ClaudeHome
$keyStill   = [bool]$env:ANTHROPIC_API_KEY -or [bool][Environment]::GetEnvironmentVariable($KeyName, 'User')
if (-not $stillThere -and -not $keyStill) {
    Write-Host "Clean. ~/.claude removed and $KeyName cleared." -ForegroundColor Green
} else {
    if ($stillThere) { Write-Host "WARNING: $ClaudeHome still present." -ForegroundColor Red }
    if ($keyStill)   { Write-Host "WARNING: $KeyName still set somewhere (check Machine scope / shell profile)." -ForegroundColor Red }
}
Write-Host ""
