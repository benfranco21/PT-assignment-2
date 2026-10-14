"""
File:         verify_q4.py
Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
Version:      PT_A2_2026_FRNBEN003_v1.0
Author:       Benjamin Franco (FRNBEN003)
Date:         2026-10-14
Purpose:      Symbolic and exact-rational (SymPy) verification of Q4: Black-Litterman portfolio
  weights (brief eq 16) and their decomposition into policy weights plus active bets.
Inputs:       None (all quantities are symbolic or fixed-seed exact rationals).
Outputs:      One PASS/FAIL line per check and a "n/N checks passed" summary on stdout.
Dependencies: Python 3.9+, sympy==1.14.0, mpmath==1.3.0 (see requirements.txt).
"""
"""SymPy check of Q4 (Black-Litterman portfolio weights).
Part A: fully symbolic, n = 3, with E[R]* left as a general vector.
Part B: exact rational arithmetic, n = 4 assets, k = 2 views, with E[R]* computed from eq (14)."""
import sympy as sp, random

def report(name, ok):
    print(f"[{'PASS' if ok else 'FAIL'}] {name}", flush=True); return ok
res = []

# ---------- Part A ----------
n = 3
g = sp.symbols('gamma', positive=True)
Es = sp.Matrix(sp.symbols('E1:4'))        # E[R]* as a general vector
Pi = sp.Matrix(sp.symbols('Pi1:4'))
s = sp.symbols('s11 s12 s13 s22 s23 s33')
Sig = sp.Matrix([[s[0], s[1], s[2]], [s[1], s[3], s[4]], [s[2], s[4], s[5]]])
one = sp.ones(n, 1); Si = Sig.inv(); C = (one.T*Si*one)[0]
f = lambda x: Si*(x - one*(one.T*Si*x)[0]/C)

q1 = lambda mu: Si*one/C + Si*(mu - one*(one.T*Si*mu)[0]/C)/g          # Q1 eq (2) as a function of mu
w_B = Si*one/C
w_BL = w_B + Si*(Es - one*(one.T*Si*Es)[0]/C)/g                         # brief eq (16)
w_S = f(Pi)/g
w_P = w_B + w_S

res.append(report('A. eq (16) equals Q1 eq (2) with mu replaced by E[R]*', sp.simplify(q1(Es) - w_BL) == sp.zeros(n, 1)))
res.append(report('A. w_BL is fully invested (sums to 1)', sp.simplify((one.T*w_BL)[0]) == 1))
res.append(report('A. the tilt (1/g) f(E[R]*) sums to 0', sp.simplify((one.T*f(Es))[0]/g) == 0))
res.append(report('A. w_BL = w_B + w_S + (1/g) f(E[R]* - Pi)', sp.simplify(w_BL - (w_B + w_S + f(Es - Pi)/g)) == sp.zeros(n, 1)))
res.append(report('A. active bets w_BL - w_P = (1/g) f(E[R]* - Pi)', sp.simplify(w_BL - w_P - f(Es - Pi)/g) == sp.zeros(n, 1)))
res.append(report('A. active bets sum to 0', sp.simplify((one.T*(w_BL - w_P))[0]) == 0))
res.append(report('A. E[R]* = Pi gives w_BL = w_P (no active bets)', sp.simplify(w_BL.subs(dict(zip(Es, Pi))) - w_P) == sp.zeros(n, 1)))

# ---------- Part B ----------
random.seed(11); R = lambda: sp.Rational(random.randint(-9, 9), random.randint(1, 5))
n, k = 4, 2
gam, tau = sp.Rational(5, 2), sp.Rational(1, 20)
Pi4 = sp.Matrix(n, 1, lambda i, j: R()); P = sp.Matrix(k, n, lambda i, j: R())
B = sp.Matrix(n, n, lambda i, j: R()); Sig4 = B*B.T + sp.eye(n)
Om = sp.diag(*[sp.Rational(random.randint(1, 9), 10) for _ in range(k)])
one4 = sp.ones(n, 1); Si4 = Sig4.inv(); C4 = (one4.T*Si4*one4)[0]
f4 = lambda x: Si4*(x - one4*(one4.T*Si4*x)[0]/C4)
T = tau*Sig4
Estar = lambda V: Pi4 + T*P.T*(P*T*P.T + Om).inv()*(V - P*Pi4)            # eq (14)
wBL = lambda V: Si4*one4/C4 + f4(Estar(V))/gam                            # eq (16)
wP4 = Si4*one4/C4 + f4(Pi4)/gam

V_agree = P*Pi4
res.append(report('B. views equal to equilibrium (V = P Pi) give E[R]* = Pi', sp.simplify(Estar(V_agree) - Pi4) == sp.zeros(n, 1)))
res.append(report('B. ... and then w_BL = w_P exactly', sp.simplify(wBL(V_agree) - wP4) == sp.zeros(n, 1)))
V_diff = P*Pi4 + sp.Matrix([sp.Rational(1, 50), -sp.Rational(1, 100)])
res.append(report('B. views away from equilibrium give non-zero active bets', sp.simplify(wBL(V_diff) - wP4) != sp.zeros(n, 1)))
res.append(report('B. w_BL still sums to 1 with real BL views', sp.simplify((one4.T*wBL(V_diff))[0]) == 1))

print(f"\n{sum(res)}/{len(res)} checks passed")
