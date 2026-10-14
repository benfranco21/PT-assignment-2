# Development notes

Repository only. This file is not included in the submission zip.

Project: STA4028Z Portfolio Theory, Assignment 2. Version: PT_A2_2026_FRNBEN003_v1.0.
Author: Benjamin Franco (FRNBEN003).

## Repository and submission

- The submission is two files: the PDF report and the code zip `submission/PT_A2_2026_FRNBEN003_v1.0.zip`. The repository itself is not handed in.
- Build the zip from any folder with `build_submission` in MATLAB (it locates itself). The zip holds one folder, `PT_A2_2026_FRNBEN003_v1.0/`, with only: `README.md`, `LICENSE-NOTICE.md`, `startup.m`, `run_all.m`, `data/raw/`, `functions/`, `scripts/`, `verification/` (no `.venv`) and empty `outputs/figures`, `outputs/tables`, `outputs/logs`.
- Never in the zip: `report/`, `.git`, `.venv`, `__pycache__`, `submission/`, existing outputs or logs, `*.asv`, `DEVELOPMENT.md`, `scripts/TEMPLATE_*.m`. `build_submission` errors if any of these end up inside.
- `submission/` is gitignored.
- Before submitting, unzip the zip into a fresh folder and run it from a different working directory (Python checks with a fresh venv, and `run(fullfile('<folder>','run_all.m'))` in MATLAB).

## Report

- Source: `report/PT_A2_2026_FRNBEN003_v1.0.tex`, images in `report/Figures/`.
- Compile from inside `report/` (the title page loads `Figures/logo.jpg`).

## Rule for scripts in scripts/

Every script in `scripts/` must run on its own as well as through `run_all`: it finds the project root from its own location with `mfilename('fullpath')` and runs `startup.m` itself if `functions/` is not on the path. Never use hard-coded paths or rely on the current folder.

Copy the header and the standalone block from `scripts/TEMPLATE_script.m` into each new script and rewrite the header. The block is:

```matlab
projectRoot = fileparts(fileparts(mfilename('fullpath')));      % scripts/ is one level below the root
if ~any(strcmp(strsplit(path, pathsep), fullfile(projectRoot, 'functions')))
    run(fullfile(projectRoot, 'startup.m'));
end
```

Then add the script's call to the marked placeholder section in `run_all.m`.

## Keeping the README accurate

`README.md` ships in the zip and is written for someone who only has the unzipped folder: no mention of git, cloning, the report or this file. Update its Requirements section if Part II starts to need a toolbox, and its folder table if folders change.

## Attribution

Copied files from Tim Gebbie's repository must keep their original header and SPDX line; list them in `LICENSE-NOTICE.md`.
