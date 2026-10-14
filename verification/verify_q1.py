"""
File:         verify_q1.py
Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
Version:      PT_A2_2026_FRNBEN003_v1.0
Author:       Benjamin Franco (FRNBEN003)
Date:         2026-10-14
Purpose:      Symbolic (SymPy) verification of Q1: first-order conditions, Lagrange multiplier,
  mutual fund separation result (brief eq 2) and second-order condition for a generic 3-asset case.
Inputs:       None (all quantities are symbolic or fixed-seed exact rationals).
Outputs:      One PASS/FAIL line per check and a "n/N checks passed" summary on stdout.
Dependencies: Python 3.9+, sympy==1.14.0, mpmath==1.3.0 (see requirements.txt).
"""
"""SymPy check of Q1 (mutual fund separation) for a generic 3-asset case."""
import sympy as sp

n = 3
g, lam = sp.symbols('gamma lambda', positive=True)
mu = sp.Matrix(sp.symbols('mu1:4'))
w  = sp.Matrix(sp.symbols('w1:4'))
s  = sp.symbols('s11 s12 s13 s22 s23 s33')
Sig = sp.Matrix([[s[0], s[1], s[2]], [s[1], s[3], s[4]], [s[2], s[4], s[5]]])  # generic symmetric
one = sp.ones(n, 1)
Si = Sig.inv()
A = (one.T*Si*mu)[0]
C = (one.T*Si*one)[0]

L = (w.T*mu)[0] - g/2*(w.T*Sig*w)[0] - lam*((w.T*one)[0] - 1)
checks = {}

# Step 1: FOCs
gradw = sp.Matrix([sp.diff(L, wi) for wi in w])
checks['1. dL/dw = mu - gamma*Sigma*w - lambda*1'] = sp.simplify(gradw - (mu - g*Sig*w - lam*one)) == sp.zeros(n, 1)
checks['1. dL/dlambda = -(w^T 1 - 1)'] = sp.simplify(sp.diff(L, lam) + ((w.T*one)[0] - 1)) == 0

# Step 2: omega(lambda)
w_lam = Si*(mu - lam*one)/g
checks['2. omega(lambda) solves FOC (i)'] = sp.simplify(mu - g*Sig*w_lam - lam*one) == sp.zeros(n, 1)

# Step 3: lambda from constraint
lam_sol = sp.solve(sp.Eq((one.T*w_lam)[0], 1), lam)[0]
checks['3. lambda = (A - gamma)/C'] = sp.simplify(lam_sol - (A - g)/C) == 0

# Step 4: separation theorem
w_star = Si*one/C + Si*(mu - one*A/C)/g
checks['4. omega(lambda*) equals brief eq (2)'] = sp.simplify(w_lam.subs(lam, lam_sol) - w_star) == sp.zeros(n, 1)
checks['4. eq (2) satisfies both FOCs'] = (sp.simplify(mu - g*Sig*w_star - lam_sol*one) == sp.zeros(n, 1)
                                          and sp.simplify((one.T*w_star)[0] - 1) == 0)

# Step 5: second-order
H = sp.hessian(L, w)
checks['5. Hessian = -gamma*Sigma'] = sp.simplify(H + g*Sig) == sp.zeros(n, n)

# 1.2 points
mvp  = Si*one/C
tilt = Si*(mu - one*A/C)/g
checks['1.2 MVP weights sum to 1'] = sp.simplify((one.T*mvp)[0]) == 1
checks['1.2 tilt weights sum to 0 (zero-cost)'] = sp.simplify((one.T*tilt)[0]) == 0
checks['1.2 MVP independent of gamma'] = all(sp.diff(x, g) == 0 for x in mvp)

for k, v in checks.items():
    print(f"[{'PASS' if v else 'FAIL'}] {k}")
print(f"\n{sum(checks.values())}/{len(checks)} checks passed")
