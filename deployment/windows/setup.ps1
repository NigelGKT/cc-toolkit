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

.PARAMETER HarvestPlugins
  Regenerate plugins.json from this machine's live plugin state (marketplaces + installed
  plugin names, stripped of machine-specific paths), then exit. Use this to "pull up" a
  plugin you installed locally so it rides to every machine. Review + commit + push after.

.PARAMETER Harvest
  The inverse of deploy, for FILES. Lists toolkit files that are on this machine but not in
  the repo (NEW-UP) or edited here and newer than the repo (CHANGED-UP), so you can pull local
  work UP into cc-toolkit. Dry-run by default; add -Force to copy them into the repo working
  tree. Review + commit + push after. Never touches secrets.

.PARAMETER Check
  Fast, silent, once-per-day drift verdict for the SessionStart hook. Prints a single line if
  local toolkit files are not yet harvested, otherwise nothing. Side-effect-free (no installs,
  no deploy). Safe to wire into a hook.

.EXAMPLE
  .\setup.ps1          # clean machine -> deploy; existing config -> audit only (no changes)
  .\setup.ps1 -Force   # deploy over an existing config (backup taken first)
  .\setup.ps1 -HarvestPlugins   # regenerate plugins.json from installed plugins, then stop
  .\setup.ps1 -Harvest          # list local toolkit files not yet in the repo (dry-run)
  .\setup.ps1 -Harvest -Force   # copy those files UP into the repo, then commit & push
  .\setup.ps1 -Check            # one-line drift verdict (used by the SessionStart hook)
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$HarvestPlugins,
    [switch]$Harvest,
    [switch]$Check
)

$ErrorActionPreference = 'Stop'

# -- Resolve locations -----------------------------------------------
$ScriptDir  = $PSScriptRoot
$RepoRoot   = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path
$ClaudeHome = Join-Path $env:USERPROFILE '.claude'

# Toolkit items this repo deploys (relative to repo root).
# 'cc-toolkit-wiki-brain' is the global-brain s.wiki vault (playbooks are folded inside it).
# 'statusline.js' backs the settings.json statusLine command (context %/model/cwd/branch).
# 'drift-check.ps1' backs the settings.json SessionStart hook (calls setup.ps1 -Check).
$ToolkitItems = @('CLAUDE.md', 'settings.json', 'skills', 'cc-toolkit-wiki-brain', 'statusline.js', 'drift-check.ps1')

# Things we must NEVER deploy or overwrite (secrets / local overrides).
$NeverTouch = @('.credentials.json', 'settings.local.json')

# Declarative plugin manifest: the marketplaces + installed plugin *names* only.
# ~/.claude/plugins/ itself is runtime state (gitignored, self-updating, machine-specific
# paths) - we version the *intent* and re-hydrate the bytes on deploy via the claude CLI.
$PluginManifest    = Join-Path $RepoRoot 'plugins.json'
$MachinePluginsDir = Join-Path $ClaudeHome 'plugins'
# Marketplaces that ship as Claude Code defaults - skip in harvest unless a listed plugin
# actually depends on one (a plugin's marketplace is the segment after its last '@').
$DefaultMarketplaces = @('claude-plugins-official')

# Keys Claude Code writes into settings.json as runtime state, dropped when comparing it so
# their churn never registers as unharvested drift:
#   - enabledPlugins / extraKnownMarketplaces: plugin hydration appends these + reorders the
#     whole file on every deploy; plugin intent lives in plugins.json, not here (the same way
#     the gitignored ~/.claude/plugins/ runtime bytes are excluded).
#   - model / effortLevel: rewritten in-place by /model and the effort toggle every session,
#     so they drift per-machine by design - machine-local runtime prefs, not shared config.
# Extend this list if new runtime keys appear.
$SettingsRuntimeKeys = @('enabledPlugins', 'extraKnownMarketplaces', 'model', 'effortLevel')

# Header + prerequisite checks: skipped for -Check (must be silent + side-effect-free,
# since it runs from a SessionStart hook on every launch).
if (-not $Check) {

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

}  # end (-not $Check) header + prerequisite guard

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

# -- Canonical-JSON compare for settings.json -----------------------------------------
# settings.json drifts after every deploy because plugin hydration rewrites it: it adds
# runtime keys ($SettingsRuntimeKeys) and reorders everything. Compare it *semantically*
# instead - drop the runtime keys, sort object keys recursively, then hash - so that noise
# no longer registers as drift. Any real content change still differs. Non-JSON falls back
# to the raw content hash.
function ConvertTo-CanonicalJson($obj) {
    if ($obj -is [System.Management.Automation.PSCustomObject]) {
        $ordered = [ordered]@{}
        foreach ($name in ($obj.PSObject.Properties.Name | Sort-Object)) {
            $ordered[$name] = ConvertTo-CanonicalJson $obj.$name
        }
        return $ordered
    }
    if ($obj -is [System.Collections.IEnumerable] -and $obj -isnot [string]) {
        return @($obj | ForEach-Object { ConvertTo-CanonicalJson $_ })
    }
    return $obj
}

function Get-SettingsHash($path) {
    $json = Get-Content $path -Raw | ConvertFrom-Json
    foreach ($k in $SettingsRuntimeKeys) {
        if ($json.PSObject.Properties.Name -contains $k) { $json.PSObject.Properties.Remove($k) }
    }
    $canon = ConvertTo-CanonicalJson $json | ConvertTo-Json -Depth 25 -Compress
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return [System.BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($canon))) }
    finally { $sha.Dispose() }
}

# Route settings.json through the canonical-JSON hash; everything else uses the raw content
# hash. Robust: a parse error on settings.json falls back to the raw hash.
function Get-CompareHash($rel, $path) {
    if ($rel -ieq 'settings.json') {
        try { return Get-SettingsHash $path } catch { return Get-ContentHash $path }
    }
    return Get-ContentHash $path
}

# -- Classify drift between this machine (~/.claude) and the repo, per toolkit file --
# Shared by the audit, -Harvest, and -Check so all three agree. Content-hash is
# authoritative for "differs"; direction (LocalNewer/RepoNewer) is a HINT from
# LastWriteTime and can mislead right after a fresh 'git clone' (which resets mtimes).
#   harvest UP  = NewLocal + LocalNewer      deploy DOWN = NewRepo + RepoNewer
function Get-ToolkitDrift {
    $insync = 0
    $localNewer = @()   # in both, differ, machine mtime newer -> harvest UP
    $repoNewer  = @()   # in both, differ, repo mtime newer    -> deploy DOWN
    $newLocal   = @()   # machine-unique (not in repo)         -> harvest UP (new)
    $newRepo    = @()   # repo-unique (not on machine)         -> deploy DOWN (add)

    foreach ($item in $ToolkitItems) {
        foreach ($f in (Get-ItemFiles $RepoRoot $item)) {
            $dest = Join-Path $ClaudeHome $f.Rel
            if (-not (Test-Path $dest)) {
                $newRepo += $f.Rel
            } elseif ((Get-CompareHash $f.Rel $f.Full) -ne (Get-CompareHash $f.Rel $dest)) {
                $repoTime = (Get-Item $f.Full).LastWriteTimeUtc
                $locTime  = (Get-Item $dest).LastWriteTimeUtc
                if ($locTime -gt $repoTime) { $localNewer += $f.Rel } else { $repoNewer += $f.Rel }
            } else { $insync++ }
        }
    }
    foreach ($item in $ToolkitItems) {
        foreach ($f in (Get-ItemFiles $ClaudeHome $item)) {
            if (-not (Test-Path (Join-Path $RepoRoot $f.Rel))) { $newLocal += $f.Rel }
        }
    }

    [pscustomobject]@{
        InSync = $insync; LocalNewer = @($localNewer); RepoNewer = @($repoNewer)
        NewLocal = @($newLocal); NewRepo = @($newRepo)
    }
}

# -- Plugin state helpers (declarative: marketplaces + plugin names only) --------
# Read this machine's live plugin intent, stripping absolute paths / timestamps / SHAs.
function Get-MachinePluginState {
    $mkts = @{}; $plugins = @()
    $km = Join-Path $MachinePluginsDir 'known_marketplaces.json'
    $ip = Join-Path $MachinePluginsDir 'installed_plugins.json'
    if (Test-Path $km) {
        $j = Get-Content $km -Raw | ConvertFrom-Json
        foreach ($name in $j.PSObject.Properties.Name) {
            $src = $j.$name.source
            if ($src -and $src.source -eq 'github' -and $src.repo) { $mkts[$name] = $src.repo }
        }
    }
    if (Test-Path $ip) {
        $j = Get-Content $ip -Raw | ConvertFrom-Json
        if ($j.plugins) { $plugins = @($j.plugins.PSObject.Properties.Name) }
    }
    [pscustomobject]@{ Marketplaces = $mkts; Plugins = @($plugins) }
}

# Read the repo manifest (declarative source of truth). Empty state if absent.
function Get-ManifestPluginState {
    $mkts = @{}; $plugins = @()
    if (Test-Path $PluginManifest) {
        $j = Get-Content $PluginManifest -Raw | ConvertFrom-Json
        if ($j.marketplaces) {
            foreach ($name in $j.marketplaces.PSObject.Properties.Name) { $mkts[$name] = $j.marketplaces.$name }
        }
        if ($j.plugins) { $plugins = @($j.plugins) }
    }
    [pscustomobject]@{ Marketplaces = $mkts; Plugins = @($plugins) }
}

# -- Harvest mode: regenerate plugins.json from this machine's live plugin state --
if ($HarvestPlugins) {
    $state = Get-MachinePluginState
    # A marketplace is kept if it's non-default, OR a listed plugin depends on it.
    $referenced = @($state.Plugins | ForEach-Object { ($_ -split '@')[-1] } | Select-Object -Unique)
    $mkts = [ordered]@{}
    foreach ($name in ($state.Marketplaces.Keys | Sort-Object)) {
        if (($DefaultMarketplaces -notcontains $name) -or ($referenced -contains $name)) {
            $mkts[$name] = $state.Marketplaces[$name]
        }
    }
    $manifest = [ordered]@{ marketplaces = $mkts; plugins = @($state.Plugins | Sort-Object) }
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -Path $PluginManifest -Encoding UTF8
    Write-Host "Regenerated plugin manifest -> $PluginManifest" -ForegroundColor Cyan
    Write-Host "  marketplaces: $(if ($mkts.Count) { $mkts.Keys -join ', ' } else { '(none)' })"
    Write-Host "  plugins     : $(if ($state.Plugins.Count) { $state.Plugins -join ', ' } else { '(none)' })"
    Write-Host ""
    Write-Host "Review, then commit & push to record these in cc-toolkit." -ForegroundColor Yellow
    return
}

# -- Harvest mode (files): pull machine-side toolkit files UP into the repo --------
# The inverse of deploy. Lists machine-unique (NEW-UP) + machine-newer (CHANGED-UP)
# toolkit files; with -Force, copies them into the repo working tree for you to review,
# commit & push. Dry-run otherwise. Never harvests secrets.
if ($Harvest) {
    if (-not (Test-Path $ClaudeHome)) {
        Write-Host "No $ClaudeHome found - nothing to harvest." -ForegroundColor Yellow
        return
    }
    $d = Get-ToolkitDrift
    $upNew = @($d.NewLocal)
    $upChg = @($d.LocalNewer)

    if (-not $upNew.Count -and -not $upChg.Count) {
        Write-Host "Nothing to harvest - the repo already has this machine's toolkit files." -ForegroundColor Green
        if ($d.RepoNewer.Count) {
            Write-Host "  (Note: $($d.RepoNewer.Count) file(s) are NEWER in the repo - deploy DOWN with -Force.)" -ForegroundColor DarkYellow
        }
        return
    }

    Write-Host "Harvest candidates (this machine -> repo):" -ForegroundColor Magenta
    if ($upNew.Count) {
        Write-Host "  NEW-UP (here, not in the repo):" -ForegroundColor Magenta
        $upNew | ForEach-Object { Write-Host "    + $_" -ForegroundColor Magenta }
    }
    if ($upChg.Count) {
        Write-Host "  CHANGED-UP (edited here, newer than the repo):" -ForegroundColor Magenta
        $upChg | ForEach-Object { Write-Host "    ^ $_" -ForegroundColor Magenta }
    }
    if ($d.RepoNewer.Count) {
        Write-Host "  SKIPPED - repo is newer (deploy DOWN instead, do not harvest):" -ForegroundColor DarkYellow
        $d.RepoNewer | ForEach-Object { Write-Host "    v $_" -ForegroundColor DarkYellow }
    }
    Write-Host ""

    if (-not $Force) {
        Write-Host "DRY RUN - nothing copied. Re-run with -Force to copy the above UP into the repo." -ForegroundColor Yellow
        return
    }

    $copied = 0
    foreach ($rel in ($upNew + $upChg)) {
        if ($NeverTouch -contains $rel) { continue }   # defensive: never harvest a secret
        $src = Join-Path $ClaudeHome $rel
        $dst = Join-Path $RepoRoot $rel
        $dstDir = Split-Path $dst -Parent
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
        Copy-Item -Path $src -Destination $dst -Force
        Write-Host "  harvested: $rel" -ForegroundColor Green
        $copied++
    }
    Write-Host ""
    Write-Host "Harvested $copied file(s) into $RepoRoot" -ForegroundColor Green
    Write-Host "Review, then commit & push to record them in cc-toolkit." -ForegroundColor Yellow
    return
}

# -- Check mode: fast, throttled drift verdict for the SessionStart hook ------------
# Prints ONE line to stdout (so a hook captures it) and exits. Throttled to once/day via
# a marker file so it adds no latency to repeated session starts. Wrapped so any error is
# swallowed - a hook must never break a session start.
if ($Check) {
    try {
        if (-not (Test-Path $ClaudeHome)) { return }
        $marker = Join-Path $ClaudeHome '.toolkit-drift-check'
        if (Test-Path $marker) {
            if (((Get-Date) - (Get-Item $marker).LastWriteTime) -lt [TimeSpan]::FromHours(24)) { return }
        }
        $d = Get-ToolkitDrift
        $up = @($d.NewLocal).Count + @($d.LocalNewer).Count
        if ($up -gt 0) {
            Write-Output "cc-toolkit: $up local file(s) not yet harvested -> run: setup.ps1 -Harvest"
        }
        Set-Content -Path $marker -Value (Get-Date -Format 'o') -Encoding UTF8
    } catch { }
    return
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

    $d = Get-ToolkitDrift

    Write-Host "  In sync (identical): $($d.InSync) file(s)"
    Write-Host ""
    # Direction (LOCAL/REPO newer) is a HINT from LastWriteTime; the content-hash is
    # authoritative for "differs". A fresh 'git clone' resets mtimes, so on a just-cloned
    # machine treat REPO NEWER with care.
    if ($d.LocalNewer.Count) {
        Write-Host "  LOCAL NEWER - edited here, newer than cc-toolkit (harvest UP):" -ForegroundColor Magenta
        $d.LocalNewer | ForEach-Object { Write-Host "    ^ $_" -ForegroundColor Magenta }
        Write-Host ""
    }
    if ($d.NewLocal.Count) {
        Write-Host "  HARVEST CANDIDATES - present here, NOT in cc-toolkit (harvest UP):" -ForegroundColor Magenta
        $d.NewLocal | ForEach-Object { Write-Host "    + $_" -ForegroundColor Magenta }
        Write-Host ""
    }
    if ($d.RepoNewer.Count) {
        Write-Host "  REPO NEWER - cc-toolkit differs and is newer (deploy DOWN with -Force):" -ForegroundColor Red
        $d.RepoNewer | ForEach-Object { Write-Host "    v $_" -ForegroundColor Red }
        Write-Host ""
    }
    if ($d.NewRepo.Count) {
        Write-Host "  WOULD BE ADDED from cc-toolkit (new on this machine):" -ForegroundColor Green
        $d.NewRepo | ForEach-Object { Write-Host "    > $_" -ForegroundColor Green }
        Write-Host ""
    }

    # plugins: declarative intent comparison (manifest vs machine), not a byte diff
    $mPlugins = Get-MachinePluginState
    $rPlugins = Get-ManifestPluginState
    $pluginHarvest   = @($mPlugins.Plugins | Where-Object { $rPlugins.Plugins -notcontains $_ })
    $pluginToInstall = @($rPlugins.Plugins | Where-Object { $mPlugins.Plugins -notcontains $_ })
    if ($pluginHarvest.Count) {
        Write-Host "  HARVEST CANDIDATES (plugins) - installed here, NOT in plugins.json:" -ForegroundColor Magenta
        $pluginHarvest | ForEach-Object { Write-Host "    + plugin: $_" -ForegroundColor Magenta }
        Write-Host "    -> run: .\deployment\windows\setup.ps1 -HarvestPlugins  (regenerates plugins.json)" -ForegroundColor Magenta
        Write-Host ""
    }
    if ($pluginToInstall.Count) {
        Write-Host "  WOULD BE INSTALLED from plugins.json (not yet on this machine):" -ForegroundColor Green
        $pluginToInstall | ForEach-Object { Write-Host "    > plugin: $_" -ForegroundColor Green }
        Write-Host ""
    }

    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. HARVEST UP - LOCAL NEWER + HARVEST CANDIDATES are local work not yet in cc-toolkit."
    Write-Host "                  Run: .\deployment\windows\setup.ps1 -Harvest   (dry-run; add -Force to copy up)"
    Write-Host "                  (plugins: -HarvestPlugins regenerates plugins.json.) Then commit & push."
    Write-Host "  2. DEPLOY DOWN - REPO NEWER + WOULD BE ADDED come from cc-toolkit; re-run with -Force to"
    Write-Host "                  install them here (a backup is taken first)."
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

# -- Persist the repo anchor -----------------------------------------
# CC_TOOLKIT_HOME lets drift-check.ps1 (the SessionStart hook) and the s.ship-cc-tlkit skill
# locate this clone on every future session with no hardcoded path. Set at User scope so it
# survives shell restarts; also set in-process so the current session sees it immediately.
# No-op when already correct. Deploy-path only - never touched by the harvest scan.
$anchor = [Environment]::GetEnvironmentVariable('CC_TOOLKIT_HOME', 'User')
if ($anchor -ne $RepoRoot) {
    [Environment]::SetEnvironmentVariable('CC_TOOLKIT_HOME', $RepoRoot, 'User')
    $env:CC_TOOLKIT_HOME = $RepoRoot
    Write-Host "  set CC_TOOLKIT_HOME -> $RepoRoot (User env)" -ForegroundColor Green
}

# -- Hydrate plugins from the declarative manifest (marketplace add + install) --
# Re-creates the plugins/ folder from intent; never version-controlled. Idempotent:
# re-adding a marketplace or re-installing a plugin is a no-op. Tolerant of offline /
# missing 'claude' - it degrades to printing the commands to run by hand.
$rPlugins = Get-ManifestPluginState
if ($rPlugins.Marketplaces.Count -or $rPlugins.Plugins.Count) {
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "Hydrating plugins from plugins.json..." -ForegroundColor Cyan
        # Native CLI exit codes drive the reporting; relax Stop so a non-zero (e.g.
        # 'already exists') doesn't abort the whole deploy.
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            foreach ($name in $rPlugins.Marketplaces.Keys) {
                $repo = $rPlugins.Marketplaces[$name]
                claude plugin marketplace add $repo | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  marketplace: $name ($repo)" -ForegroundColor Green
                } else {
                    Write-Host "  [note] marketplace '$name' add returned $LASTEXITCODE (may already exist) - continuing" -ForegroundColor Yellow
                }
            }
            foreach ($p in $rPlugins.Plugins) {
                claude plugin install $p --scope user | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  installed: $p" -ForegroundColor Green
                } else {
                    Write-Host "  [note] plugin '$p' install returned $LASTEXITCODE (may already be installed) - continuing" -ForegroundColor Yellow
                }
            }
        } finally {
            $ErrorActionPreference = $prevEAP
        }
    } else {
        Write-Host ""
        Write-Host "Plugins not hydrated - 'claude' not on PATH yet. After install, run:" -ForegroundColor Yellow
        foreach ($name in $rPlugins.Marketplaces.Keys) { Write-Host "  claude plugin marketplace add $($rPlugins.Marketplaces[$name])" }
        foreach ($p in $rPlugins.Plugins) { Write-Host "  claude plugin install $p --scope user" }
    }
}

Write-Host ""
Write-Host "Toolkit deployed to $ClaudeHome" -ForegroundColor Green
Write-Host "Next:" -ForegroundColor Cyan
Write-Host '  $env:ANTHROPIC_API_KEY = "sk-ant-..."   # from your password manager'
Write-Host "  claude"
Write-Host ""
