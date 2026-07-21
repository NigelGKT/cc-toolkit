---
name: s.venv-setup
description: Set up or sync a Python virtual environment for the current project — creates .venv, scans the project's actual imports, installs/syncs requirements.txt against them, adds .gitignore entries, and configures the VS Code interpreter. Safe to re-run (reconciles added/removed imports each time). Use when the user asks to set up a venv, initialize a Python project environment, "create a virtual environment", or when a Python project in the current working directory has no .venv yet.
---

# venv setup

Thin wrapper around the toolkit's bundled `scripts/new-pyproject.ps1`. All the actual logic
(venv creation, import scanning, requirements.txt sync, .gitignore, VS Code interpreter) lives
in that script — this skill just locates it and runs it against the right folder.

## Steps

1. **Locate the script.** This skill's own base directory is injected above (or in the
   activation message) as something like `<toolkit-root>/skills/s.venv-setup`. The script lives
   two levels up, in `<toolkit-root>/scripts/new-pyproject.ps1` — `scripts/` and `skills/` are
   sibling folders under the toolkit root (both deployed to `~/.claude` by `setup.ps1`/`setup.sh`).
2. **Identify the target project folder.** This is the user's current project directory — the
   folder the venv should be created *in* — not this skill's own folder and not the toolkit root.
   If ambiguous, ask which folder to target rather than guessing.
3. **Run it** via the PowerShell tool, with the working directory set to the target project
   folder:
   ```
   powershell -ExecutionPolicy Bypass -File "<toolkit-root>\scripts\new-pyproject.ps1"
   ```
   To install specific packages instead of relying on import-scanning, pass them as trailing
   arguments (e.g. `... new-pyproject.ps1 pandas requests`).
4. **Report the result** — interpreter path and whether packages were installed/removed, per the
   script's own summary output.

## Notes

- Windows/PowerShell only (matches this toolkit's primary platform).
- On dependency/import breakage, delete the project's `.venv/` folder and re-run.
- The script is idempotent — safe to invoke again on a project that already has a `.venv`; it
  reconciles `requirements.txt` against current imports rather than duplicating setup.
