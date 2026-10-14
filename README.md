# PT-assignment-2

STA4028Z Portfolio Theory, Assignment 2: Backtesting a Black-Litterman Portfolio
(University of Cape Town, lecturer Tim Gebbie).

- Author: Benjamin Franco (FRNBEN003)
- Version identifier: PT_A2_2026_FRNBEN003_v1.0

## Requirements

- MATLAB: tested on MATLAB R2026a. Part II uses base MATLAB only; no toolboxes are needed at present (this section will be updated if that changes).
- Python 3.9 or later, for the Part I SymPy checks only. Tested on Python 3.9.6 with `sympy==1.14.0` and `mpmath==1.3.0`.
- An internet connection is needed once, to install the two Python packages.

## Part II: MATLAB backtest

1. Open MATLAB.
2. Change the current folder to the repository root (the folder that contains `run_all.m`):
   ```matlab
   cd('path/to/PT-assignment-2')
   ```
3. Run:
   ```matlab
   run_all
   ```

`run_all` adds `functions/` to the path, creates the `outputs/` subfolders if missing, prints the date, MATLAB version and installed toolboxes, checks the raw data file against the SHA-256 value in `data/raw/DATA-CHECKSUM.txt`, runs the Part II scripts in order, and finishes by printing `run_all completed`. It stops with an error message if the data file is missing or has been changed.

What it produces:

- `outputs/logs/run_log_<timestamp>.txt`: a copy of everything printed during the run.
- `outputs/figures/`: figures written by the Part II scripts.
- `outputs/tables/`: tables written by the Part II scripts.
- `data/derived/`: intermediate data written by the Part II scripts.

The Part II scripts have not been added yet, so at present only the log is produced. Random numbers use `rng(20261014,'twister')`.

## Part I: SymPy verification checks

Run these commands from the repository root.

macOS / Linux:

```bash
python3 -m venv verification/.venv
source verification/.venv/bin/activate
pip install -r verification/requirements.txt
python verification/run_all_checks.py
```

Windows (Command Prompt):

```bat
python -m venv verification\.venv
verification\.venv\Scripts\activate.bat
pip install -r verification\requirements.txt
python verification\run_all_checks.py
```

Windows (PowerShell): use `verification\.venv\Scripts\Activate.ps1` for the activate step.

The script prints a timestamp, the Python and SymPy versions, then every check as `[PASS]` or `[FAIL]`, and ends with `SUMMARY: all 6 scripts passed`. It exits with a non-zero status if any check fails or any script errors. It can be run from any folder. It takes about 2 minutes.

## Folder structure

| Path | Contents |
| --- | --- |
| `run_all.m` | Single entry point for Part II. |
| `startup.m` | Adds `functions/` and its subfolders to the MATLAB path. |
| `LICENSE-NOTICE.md` | Attribution for material from Tim Gebbie's public repository. |
| `data/raw/` | Original data file and `DATA-CHECKSUM.txt`. Not modified by any code. |
| `data/derived/` | Data produced by the code. Contents are not tracked by git. |
| `functions/data/` | MATLAB functions for loading and cleaning data. |
| `functions/portfolio/` | MATLAB functions for portfolio construction. |
| `functions/performance/` | MATLAB functions for performance measures. |
| `functions/diagnostics/` | MATLAB functions for diagnostic checks. |
| `scripts/` | MATLAB scripts for Part II, called by `run_all.m`. |
| `verification/` | Part I SymPy scripts, `requirements.txt` and `run_all_checks.py`. |
| `outputs/figures/` | Figures produced by the code. Not tracked by git. |
| `outputs/tables/` | Tables produced by the code. Not tracked by git. |
| `outputs/logs/` | Run logs from `run_all`. Not tracked by git. |
| `report/` | LaTeX source of the report; `report/Figures/` holds its images. |

## Naming convention and version

- Version identifier: `PT_A2_2026_FRNBEN003_v1.0` (project, year, student number, version).
- The report file is named with the version identifier.
- Every `.m` and `.py` file starts with a header giving its file name, project, version, author, date, purpose, inputs, outputs and dependencies.
- Python check scripts are named `verify_q<question>.py`, for example `verify_q3_2_1.py` for Question 3.2.1.

## Report

The report is `report/PT_A2_2026_FRNBEN003_v1.0.tex`. Compile it from inside the `report/` folder (it loads `Figures/logo.jpg`).
