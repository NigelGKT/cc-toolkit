---
type: playbook
tags: [python, venv, packaging, tooling, cc-toolkit]
origin: pyvenv_scripts / NigelGKT/scripts repo (new-pyproject.ps1), folded into cc-toolkit 2026-07-21
updated: 2026-07-21
status: stable
---

# Python venv Setup Workflow

How to stand up (or resync) a project-local Python virtual environment, using the toolkit's
bundled `scripts/new-pyproject.ps1` via the `/s.venv-setup` skill.

## What it does

Run it from — or point the skill at — the target project folder:

- Creates `.venv` if it doesn't already exist (skips silently if it does).
- **Scans the project's actual `.py` files for imports** (via `ast`, not string matching),
  maps known import-name → pip-package-name mismatches (`cv2` → `opencv-python`, `PIL` →
  `Pillow`, `bs4` → `beautifulsoup4`, `win32*` → `pywin32`, etc.), and excludes stdlib modules
  and the project's own local modules/packages.
- **First run** (no `requirements.txt` yet): installs everything detected, then freezes to
  `requirements.txt`.
- **Subsequent runs**: diffs currently-installed top-level packages against currently-detected
  imports — installs anything newly imported, **uninstalls anything no longer imported**, then
  re-freezes. This is why it's safe (and intended) to re-run after adding/removing imports
  instead of hand-editing `requirements.txt`.
- Creates or extends `.gitignore` (`.venv/`, `__pycache__/`, `.vscode/`, OS cruft) and
  `.vscode/settings.json` (points the VS Code Python interpreter at `.venv`).

## Gotchas

- **Packages are installed one at a time**, not as a single batched `pip install a b c`. This
  is deliberate: if one import name doesn't resolve on PyPI under a different pip name (and
  isn't in the script's `pip_map`), it fails alone instead of taking the whole batch down.
  Fix: add the mismatch to `pip_map` in the script's embedded scan script.
- **Dependency/import breakage after a sync** (conflicting transitive versions, a stale
  `.venv` in a weird state): delete `.venv/` entirely and re-run rather than debugging in
  place — the script rebuilds cleanly from `requirements.txt` + current imports either way.
- Manual freeze, if ever needed outside the script's own auto-freeze step:
  `".\.venv\Scripts\python.exe" -m pip freeze > requirements.txt`.

## Related
- [[cc-toolkit-deploy-lifecycle]] — how `scripts/` and `skills/` deploy to every machine
