"""
File:         run_all_checks.py
Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
Version:      PT_A2_2026_FRNBEN003_v1.0
Author:       Benjamin Franco (FRNBEN003)
Date:         2026-10-14
Purpose:      Run every Part I SymPy verification script in a fixed order and report the results.
              Exits with a non-zero status if any script fails to run or reports a FAIL line.
Inputs:       verify_q1.py, verify_q2.py, verify_q3_1.py, verify_q3_2_1.py, verify_q3_2_2.py,
              verify_q4.py (same folder as this file).
Outputs:      Timestamp, Python and SymPy versions, each script's output, and a final summary
              on stdout. Exit code 0 if all checks pass, 1 otherwise.
Dependencies: Python 3.9+, sympy==1.14.0, mpmath==1.3.0 (see requirements.txt).
"""
import datetime
import subprocess
import sys
from pathlib import Path

import sympy

HERE = Path(__file__).resolve().parent
SCRIPTS = ["verify_q1.py", "verify_q2.py", "verify_q3_1.py",
           "verify_q3_2_1.py", "verify_q3_2_2.py", "verify_q4.py"]


def main():
    print(f"Run time : {datetime.datetime.now().isoformat(timespec='seconds')}")
    print(f"Python   : {sys.version.split()[0]}")
    print(f"SymPy    : {sympy.__version__}")
    failed = []
    for name in SCRIPTS:
        print(f"\n{'=' * 70}\n{name}\n{'=' * 70}", flush=True)
        proc = subprocess.run([sys.executable, str(HERE / name)],
                              capture_output=True, text=True, cwd=HERE)
        print(proc.stdout, end="")
        if proc.stderr:
            print(proc.stderr, end="", file=sys.stderr)
        n_fail = proc.stdout.count("[FAIL]")
        if proc.returncode != 0 or n_fail > 0:
            failed.append(name)
            print(f"--> {name}: ERROR (exit code {proc.returncode}, {n_fail} FAIL lines)")
        else:
            print(f"--> {name}: all PASS")
    print(f"\n{'=' * 70}")
    if failed:
        print(f"SUMMARY: {len(failed)} of {len(SCRIPTS)} scripts failed: {', '.join(failed)}")
        return 1
    print(f"SUMMARY: all {len(SCRIPTS)} scripts passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
