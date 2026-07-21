# new-pyproject.ps1
# Sets up a clean Python environment for the project folder it's run against.
#
# Usual invocation: via the /s.venv-setup skill (Claude Code) — it runs this automatically
# against whatever project folder is active, on any machine the toolkit is deployed to.
#
# Direct invocation (run from the target project folder):
#   powershell -ExecutionPolicy Bypass -File "<cc-toolkit>\scripts\new-pyproject.ps1"
#
# To install specific packages instead of reading requirements.txt:
#   powershell -ExecutionPolicy Bypass -File "<cc-toolkit>\scripts\new-pyproject.ps1" pandas requests

param(
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Packages
)

$ErrorActionPreference = "Stop"

$ProjectDir   = (Get-Location).Path
$VenvDir      = Join-Path $ProjectDir ".venv"
$VenvPython   = Join-Path $VenvDir "Scripts\python.exe"
$VscodeDir    = Join-Path $ProjectDir ".vscode"
$SettingsFile = Join-Path $VscodeDir "settings.json"
$Gitignore    = Join-Path $ProjectDir ".gitignore"
$Requirements = Join-Path $ProjectDir "requirements.txt"

Write-Host ""
Write-Host "==> Setting up Python project in: $ProjectDir"

# 1. Create .venv
if (Test-Path $VenvDir) {
    Write-Host "==> .venv already exists, skipping creation"
} else {
    python -m venv .venv
    Write-Host "==> .venv created"
}

# 2. Scan project for imports (always runs)
$scanScript = @'
import sys, ast
from pathlib import Path

project_dir = sys.argv[1]

if hasattr(sys, 'stdlib_module_names'):
    stdlib = sys.stdlib_module_names
else:
    stdlib = set(sys.builtin_module_names)

pip_map = {
    'cv2':        'opencv-python',
    'PIL':        'Pillow',
    'sklearn':    'scikit-learn',
    'bs4':        'beautifulsoup4',
    'yaml':       'PyYAML',
    'dotenv':     'python-dotenv',
    'serial':     'pyserial',
    'dateutil':   'python-dateutil',
    'attr':       'attrs',
    'Crypto':     'pycryptodome',
    'jwt':        'PyJWT',
    'docx':       'python-docx',
    'pptx':       'python-pptx',
    'magic':      'python-magic',
    'usb':        'pyusb',
    'win32api':   'pywin32',
    'win32com':   'pywin32',
    'win32con':   'pywin32',
    'win32event': 'pywin32',
    'win32gui':   'pywin32',
    'win32clipboard': 'pywin32',
    'pythoncom':  'pywin32',
    'pywintypes': 'pywin32',
}

py_files = [
    path for path in Path(project_dir).rglob('*.py')
    if not any(p in {'.venv', 'venv', 'env'} for p in path.parts)
]

# Names that resolve to a file/package already inside the project are not
# PyPI packages - exclude them so a local `import api_layer` (your own
# api_layer.py) doesn't get treated as something to pip install.
local_modules = {path.stem for path in py_files}
for init_path in Path(project_dir).rglob('__init__.py'):
    if not any(p in {'.venv', 'venv', 'env'} for p in init_path.parts):
        local_modules.add(init_path.parent.name)

imports = set()
for path in py_files:
    try:
        tree = ast.parse(path.read_text(encoding='utf-8', errors='ignore'))
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    imports.add(alias.name.split('.')[0])
            elif isinstance(node, ast.ImportFrom):
                if node.module and node.level == 0:
                    imports.add(node.module.split('.')[0])
    except:
        pass

packages = sorted(set(
    pip_map.get(imp, imp)
    for imp in imports
    if imp not in stdlib and not imp.startswith('_') and imp not in local_modules
))
print('\n'.join(packages))
'@

$tempScript = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.py'
$scanScript | Set-Content $tempScript -Encoding UTF8
try {
    $detected = & $VenvPython $tempScript $ProjectDir 2>$null | Where-Object { $_ -ne "" }
} finally {
    Remove-Item $tempScript -ErrorAction SilentlyContinue
}

if ($detected.Count -gt 0) {
    Write-Host "==> Detected imports: $($detected -join ', ')"
} else {
    Write-Host "==> No third-party imports detected in project"
}

# 3. Install packages
$didInstall = $false
$basePackages = @('pip', 'setuptools', 'wheel')

# Installs one package per pip invocation so a name that doesn't resolve on
# PyPI (e.g. an import name that differs from its pip package name and isn't
# in pip_map) only skips itself - it can't take the rest of the batch down
# with it the way a single combined `pip install a b c` does.
function Install-PackageList {
    param([string[]]$Names, [string]$Python)
    $failed = @()
    foreach ($name in $Names) {
        $proc = Start-Process -FilePath $Python -ArgumentList @("-m", "pip", "install", $name) -Wait -NoNewWindow -PassThru
        if ($proc.ExitCode -ne 0) {
            $failed += $name
        }
    }
    if ($failed.Count -gt 0) {
        Write-Host "==> Could not resolve as pip packages, skipped: $($failed -join ', ')" -ForegroundColor Yellow
        Write-Host "==> If one of these is a real package under a different pip name, add it to pip_map in the scan script above" -ForegroundColor Yellow
    }
}

if ($Packages.Count -gt 0) {
    # Explicit packages passed - install those plus anything detected
    Write-Host "==> Installing specified packages: $($Packages -join ', ')"
    Install-PackageList -Names $Packages -Python $VenvPython
    $didInstall = $true

    if ($detected.Count -gt 0) {
        Write-Host "==> Installing detected packages (pip skips already-installed)"
        Install-PackageList -Names $detected -Python $VenvPython
    }
} elseif (Test-Path $Requirements) {
    # Existing project - sync installs to match current imports

    # Get top-level installed packages only (excludes transitive dependencies)
    $topLevel = & $VenvPython -m pip list --not-required --format=freeze 2>$null |
        Where-Object { $_ -match '==' } |
        ForEach-Object { ($_ -split '==')[0].ToLower().Trim() } |
        Where-Object { $_ -notin $basePackages }

    $detectedNorm = $detected | ForEach-Object { $_.ToLower().Trim() }

    # Remove packages that are no longer imported
    $toRemove = $topLevel | Where-Object { $_ -notin $detectedNorm }
    if ($toRemove.Count -gt 0) {
        Write-Host "==> Removing packages no longer imported: $($toRemove -join ', ')"
        $removeArgs = @("-m", "pip", "uninstall", "-y") + $toRemove
        Start-Process -FilePath $VenvPython -ArgumentList $removeArgs -Wait -NoNewWindow
        $didInstall = $true
    }

    # Install any new imports not yet installed
    $toAdd = $detectedNorm | Where-Object { $_ -notin $topLevel }
    if ($toAdd.Count -gt 0) {
        Write-Host "==> Installing new packages: $($toAdd -join ', ')"
        Install-PackageList -Names $toAdd -Python $VenvPython
        $didInstall = $true
    }

    if (-not $didInstall) {
        Write-Host "==> Installed packages already match imports - nothing to change"
    }
} else {
    # First run - no requirements.txt yet
    if ($detected.Count -gt 0) {
        Write-Host "==> Installing detected packages"
        Install-PackageList -Names $detected -Python $VenvPython
        $didInstall = $true
    } else {
        Write-Host "==> No packages installed - venv is empty"
        Write-Host "==> Add imports to your .py files or run with package names, e.g.:"
        Write-Host "         powershell -ExecutionPolicy Bypass -File new-pyproject.ps1 pandas requests"
    }
}

if ($didInstall -or (Test-Path $Requirements)) {
    Start-Process -FilePath $VenvPython -ArgumentList "-m", "pip", "freeze" -Wait -NoNewWindow -RedirectStandardOutput $Requirements
    Write-Host "==> requirements.txt updated"
}

# 3. Create .gitignore
if (-not (Test-Path $Gitignore)) {
    $gitignoreLines = @(
        "# Virtual environment",
        ".venv/",
        "venv/",
        "env/",
        "",
        "# Python cache",
        "__pycache__/",
        "*.pyc",
        "*.pyo",
        "*.pyd",
        "",
        "# VS Code",
        ".vscode/",
        "",
        "# OS",
        "Thumbs.db",
        "Desktop.ini",
        ".DS_Store",
        "",
        "# Temp / editor",
        "*.tmp",
        "*~"
    )
    $gitignoreLines | Set-Content $Gitignore
    Write-Host "==> .gitignore created"
} else {
    if (-not (Select-String -Path $Gitignore -Pattern "^\.venv" -Quiet)) {
        Add-Content $Gitignore ""
        Add-Content $Gitignore "# Virtual environment"
        Add-Content $Gitignore ".venv/"
        Write-Host "==> Added .venv/ to existing .gitignore"
    } else {
        Write-Host "==> .gitignore already covers .venv/"
    }
}

# 4. Configure VS Code interpreter
if (-not (Test-Path $VscodeDir)) {
    New-Item -ItemType Directory $VscodeDir | Out-Null
}

if (-not (Test-Path $SettingsFile)) {
    $settingsLines = @(
        "{",
        '    "python.defaultInterpreterPath": "${workspaceFolder}/.venv/Scripts/python.exe",',
        '    "python.terminal.activateEnvironment": true',
        "}"
    )
    $settingsLines | Set-Content $SettingsFile
    Write-Host "==> .vscode/settings.json created"
} else {
    Write-Host "==> .vscode/settings.json already exists, skipping"
}

# 5. Summary
Write-Host ""
Write-Host "Done. Project environment ready."
Write-Host "  Interpreter : $VenvPython"
Write-Host "  VS Code     : Open this folder - interpreter auto-selects"
Write-Host ""
