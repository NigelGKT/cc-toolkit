<#
.SYNOPSIS
  Deploy the GKT cc-toolkit into this machine's global Claude Code config (~/.claude).

.DESCRIPTION
  Safe by default.
  - CLEAN machine (no existing config): deploys straight away.
  - EXISTING config detected: does NOT overwrite. It audits what differs, prints a
    HARVEST report (what's on this machine but not in cc-toolkit), and stops so you
    can pull anything worth keeping UP into the repo first. Re-run with -Force to
    deploy after review (a lightweight backup of the toolkit files is taken first).

  Never touches secrets (.credentials.json, settings.local.json) or runtime state.

.PARAMETER Force
  Proceed with deployment when an existing config is detected, AFTER you've reviewed
  the harvest report. Existing toolkit files are backed up to ~/.claude.backup-<ts> first.

.EXAMPLE
  .\setup.ps1          # clean machine -> deploy; existing config -> audit only (no changes)
  .\setup.ps1 -Force   # deploy over an existing config (backup taken first)
#>
[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# -- Resolve locations -----------------------------------------------
$ScriptDir  = $PSScriptRoot
$RepoRoot   = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path
$ClaudeHome = Join-Path $env:USERPROFILE '.claude'

# Toolkit items this repo deploys (relative to repo root).
# 'cc-toolkit-wiki-brain' is the global-brain s.wiki vault (playbooks are folded inside it).
$ToolkitItems = @('CLAUDE.md', 'settings.json', 'skills', 'cc-toolkit-wiki-brain')

# Things we must NEVER deploy or overwrite (secrets / local overrides).
$NeverTouch = @('.credentials.json', 'settings.local.json')

Write-Host ""
Write-Host "GKT cc-toolkit setup" -ForegroundColor Cyan
Write-Host "  repo : $RepoRoot"
Write-Host "  dest : $ClaudeHome"
Write-Host ""

# -- Prerequisite check (git: report only; Node.js + Claude Code: auto-install) --
Write-Host "Prerequisites:"

# git - report only (requires manual install / admin judgment)
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "  [ok]   git" -ForegroundColor Green
} else {
    Write-Host "  [miss] git  ->  install from https://git-scm.com" -ForegroundColor Yellow
}

# Node.js - auto-install via winget if missing
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Host "  [ok]   Node.js" -ForegroundColor Green
} else {
    Write-Host "  [miss] Node.js - attempting install via winget..." -ForegroundColor Yellow
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')
        if (Get-Command node -ErrorAction SilentlyContinue) {
            Write-Host "  [ok]   Node.js (just installed)" -ForegroundColor Green
        } else {
            Write-Host "  [warn] Node.js installed - restart terminal then re-run this script." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [miss] Node.js  ->  install LTS from https://nodejs.org  (winget unavailable)" -ForegroundColor Yellow
    }
}

# Claude Code - auto-install via npm if missing
if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Host "  [ok]   Claude Code" -ForegroundColor Green
} else {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-Host "  [miss] Claude Code - installing via npm..." -ForegroundColor Yellow
        npm install -g @anthropic-ai/claude-code
        if (Get-Command claude -ErrorAction SilentlyContinue) {
            Write-Host "  [ok]   Claude Code (just installed)" -ForegroundColor Green
        } else {
            Write-Host "  [warn] Claude Code installed - restart terminal then re-run this script." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [miss] Claude Code  ->  install Node.js first, then: npm install -g @anthropic-ai/claude-code" -ForegroundColor Yellow
    }
}

Write-Host ""

# -- Helper: enumerate the files under a toolkit item (file or dir) --
function Get-ItemFiles($base, $item) {
    $p = Join-Path $base $item
    if (-not (Test-Path $p)) { return @() }
    if (Test-Path $p -PathType Leaf) {
        return @([pscustomobject]@{ Rel = $item; Full = $p })
    }
    Get-ChildItem -Path $p -Recurse -File | ForEach-Object {
        [pscustomobject]@{ Rel = $_.FullName.Substring($base.Length).TrimStart('\'); Full = $_.FullName }
    }
}

# -- Content hash that ignores line endings (CRLF vs LF) -------------
# A raw byte hash flags a CRLF-checked-out clone as "different" from an
# LF working copy even when the content is identical. The audit should
# report real drift only, so we normalise line endings before hashing.
# Binary files (any NUL byte) fall back to a raw byte hash.
function Get-ContentHash($path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    if ([Array]::IndexOf($bytes, [byte]0) -ge 0) {
        $toHash = $bytes
    } else {
        $text = [System.Text.Encoding]::UTF8.GetString($bytes)
        $norm = ($text -replace "`r`n", "`n") -replace "`r", "`n"
        $toHash = [System.Text.Encoding]::UTF8.GetBytes($norm)
    }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return [System.BitConverter]::ToString($sha.ComputeHash($toHash)) }
    finally { $sha.Dispose() }
}

# -- Detect an existing Claude Code config ---------------------------
$existing = $false
if (Test-Path $ClaudeHome) {
    foreach ($item in $ToolkitItems) {
        if (Test-Path (Join-Path $ClaudeHome $item)) { $existing = $true; break }
    }
}

# -- EXISTING CONFIG + no -Force: audit + harvest report, change nothing --
if ($existing -and -not $Force) {
    Write-Host "Existing Claude Code config detected at $ClaudeHome" -ForegroundColor Yellow
    Write-Host "AUDIT MODE - nothing will be changed. Reviewing differences..." -ForegroundColor Yellow
    Write-Host ""

    $conflicts = @(); $additions = @(); $insync = 0

    # repo -> machine (what cc-toolkit would add or change)
    foreach ($item in $ToolkitItems) {
        foreach ($f in (Get-ItemFiles $RepoRoot $item)) {
            $dest = Join-Path $ClaudeHome $f.Rel
            if (-not (Test-Path $dest)) {
                $additions += $f.Rel
            } elseif ((Get-ContentHash $f.Full) -ne (Get-ContentHash $dest)) {
                $conflicts += $f.Rel
            } else { $insync++ }
        }
    }

    # machine -> repo (machine-unique = harvest candidates)
    $harvest = @()
    foreach ($item in $ToolkitItems) {
        foreach ($f in (Get-ItemFiles $ClaudeHome $item)) {
            if (-not (Test-Path (Join-Path $RepoRoot $f.Rel))) { $harvest += $f.Rel }
        }
    }

    Write-Host "  In sync (identical): $insync file(s)"
    Write-Host ""
    if ($conflicts.Count) {
        Write-Host "  CONFLICTS - this machine differs from cc-toolkit (review before overwriting):" -ForegroundColor Red
        $conflicts | ForEach-Object { Write-Host "    ~ $_" -ForegroundColor Red }
        Write-Host ""
    }
    if ($harvest.Count) {
        Write-Host "  HARVEST CANDIDATES - present here, NOT in cc-toolkit (pull these UP first):" -ForegroundColor Magenta
        $harvest | ForEach-Object { Write-Host "    + $_" -ForegroundColor Magenta }
        Write-Host ""
    }
    if ($additions.Count) {
        Write-Host "  WOULD BE ADDED from cc-toolkit (new on this machine):" -ForegroundColor Green
        $additions | ForEach-Object { Write-Host "    > $_" -ForegroundColor Green }
        Write-Host ""
    }

    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. HARVEST  - copy anything above worth keeping into the cc-toolkit repo, commit & push."
    Write-Host "  2. REVIEW   - decide whether cc-toolkit's version should win on each CONFLICT."
    Write-Host "  3. DEPLOY   - re-run with -Force to install (a backup is taken first)."
    Write-Host ""
    Write-Host "No changes were made." -ForegroundColor Yellow
    return
}

# -- Lightweight backup of exactly the toolkit files we may overwrite -
if (-not (Test-Path $ClaudeHome)) {
    New-Item -ItemType Directory -Path $ClaudeHome -Force | Out-Null
}
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = "$ClaudeHome.backup-$stamp"
$backedUp = $false
foreach ($item in $ToolkitItems) {
    $p = Join-Path $ClaudeHome $item
    if (Test-Path $p) {
        if (-not (Test-Path $backup)) { New-Item -ItemType Directory -Path $backup -Force | Out-Null }
        Copy-Item -Path $p -Destination (Join-Path $backup $item) -Recurse -Force
        $backedUp = $true
    }
}
if ($backedUp) { Write-Host "Backed up existing toolkit files -> $backup" -ForegroundColor Cyan }

# -- Deploy toolkit items (merge dirs; never secrets) ----------------
foreach ($item in $ToolkitItems) {
    $src = Join-Path $RepoRoot $item
    if (-not (Test-Path $src)) { continue }
    $dst = Join-Path $ClaudeHome $item
    if (Test-Path $src -PathType Leaf) {
        Copy-Item -Path $src -Destination $dst -Force
    } else {
        if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst -Force | Out-Null }
        Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force
    }
    Write-Host "  deployed: $item" -ForegroundColor Green
}

# Defensive: warn if a secret ever ended up in the repo (should be impossible).
foreach ($secret in $NeverTouch) {
    if (Test-Path (Join-Path $RepoRoot $secret)) {
        Write-Host "  WARNING: $secret exists in the repo - it must never be committed." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Toolkit deployed to $ClaudeHome" -ForegroundColor Green
Write-Host "Next:" -ForegroundColor Cyan
Write-Host '  $env:ANTHROPIC_API_KEY = "sk-ant-..."   # from your password manager'
Write-Host "  claude"
Write-Host ""
