"""
File:         verify_q2.py
Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
Version:      PT_A2_2026_FRNBEN003_v1.0
Author:       Benjamin Franco (FRNBEN003)
Date:         2026-10-14
Purpose:      Symbolic (SymPy) verification of Q2: three-fund separation (brief eqs 4-6) with
  equilibrium returns Pi, for a generic 3-asset case.
Inputs:       None (all quantities are symbolic or fixed-seed exact rationals).
Outputs:      One PASS/FAIL line per check and a "n/N checks passed" summary on stdout.
Dependencies: Python 3.9+, sympy==1.14.0, mpmath==1.3.0 (see requirements.txt).
"""
"""SymPy check of Q2 (three-fund separation with equilibrium views) for a generic 3-asset case."""
import sympy as sp

n = 3
g = sp.symbols('gamma', positive=True)
mu = sp.Matrix(sp.symbols('mu1:4'))
Pi = sp.Matrix(sp.symbols('Pi1:4'))
s  = sp.symbols('s11 s12 s13 s22 s23 s33')
Sig = sp.Matrix([[s[0], s[1], s[2]], [s[1], s[3], s[4]], [s[2], s[4], s[5]]])
one = sp.ones(n, 1)
Si = Sig.inv()
C = (one.T*Si*one)[0]
Z = sp.zeros
checks = {}

# Q1 result
w_star = Si*one/C + Si*(mu - one*(one.T*Si*mu)[0]/C)/g

# f is linear
f = lambda x: Si*(x - one*(one.T*Si*x)[0]/C)
checks['Step 1. f(Pi + (mu-Pi)) = f(Pi) + f(mu-Pi)  (linearity)'] = sp.simplify(f(Pi + (mu-Pi)) - f(Pi) - f(mu-Pi)) == Z(n,1)

# Brief eqs (4)-(6)
w_B = Si*one/C
w_S = (Si/g) * ((Pi*one.T - one*Pi.T)/C) * Si*one
w_T = (Si/g) * (((mu-Pi)*one.T - one*(mu-Pi).T)/C) * Si*one

# Step 2: outer-product form = simple form
checks['Step 2. identity Pi^T Sinv 1 = 1^T Sinv Pi'] = sp.simplify((Pi.T*Si*one)[0] - (one.T*Si*Pi)[0]) == 0
checks['Step 2. (Pi1^T - 1Pi^T) Sinv 1 / C = Pi - 1(1^T Sinv Pi)/C'] = sp.simplify((Pi*one.T - one*Pi.T)*Si*one/C - (Pi - one*(one.T*Si*Pi)[0]/C)) == Z(n,1)
checks['Step 2. eq (5) equals (1/g) f(Pi)'] = sp.simplify(w_S - f(Pi)/g) == Z(n,1)
checks['Step 2. eq (6) equals (1/g) f(mu - Pi)'] = sp.simplify(w_T - f(mu-Pi)/g) == Z(n,1)

# Whole decomposition
checks['Result. w_B + w_S + w_T equals Q1 eq (2)'] = sp.simplify(w_B + w_S + w_T - w_star) == Z(n,1)

# Step 3: budgets
s1 = lambda w: sp.simplify((one.T*w)[0])
checks['Step 3. w_B sums to 1'] = s1(w_B) == 1
checks['Step 3. w_S sums to 0'] = s1(w_S) == 0
checks['Step 3. w_T sums to 0'] = s1(w_T) == 0
checks['Step 3. policy w_P = w_B + w_S sums to 1'] = s1(w_B + w_S) == 1
checks['Step 3. diag(Pi1^T - 1Pi^T) = 0'] = all(sp.simplify((Pi*one.T - one*Pi.T)[i,i]) == 0 for i in range(n))
checks['Step 3. (Pi1^T - 1Pi^T)_ij = Pi_i - Pi_j'] = all(sp.simplify((Pi*one.T - one*Pi.T)[i,j] - (Pi[i]-Pi[j])) == 0 for i in range(n) for j in range(n))
checks['Extra. mu = Pi gives w_T = 0 (no tactical bets in equilibrium)'] = sp.simplify(w_T.subs(dict(zip(mu, Pi)))) == Z(n,1)

for k, v in checks.items():
    print(f"[{'PASS' if v else 'FAIL'}] {k}")
print(f"\n{sum(checks.values())}/{len(checks)} checks passed")
