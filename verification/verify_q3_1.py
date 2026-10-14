"""
File:         verify_q3_1.py
Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
Version:      PT_A2_2026_FRNBEN003_v1.0
Author:       Benjamin Franco (FRNBEN003)
Date:         2026-10-14
Purpose:      Symbolic (SymPy) verification of Q3.1: Lagrangian solution with certain views
  (brief eq 10), n = 3 assets and k = 2 views.
Inputs:       None (all quantities are symbolic or fixed-seed exact rationals).
Outputs:      One PASS/FAIL line per check and a "n/N checks passed" summary on stdout.
Dependencies: Python 3.9+, sympy==1.14.0, mpmath==1.3.0 (see requirements.txt).
"""
"""SymPy check of Q3.1 (certain views, Lagrangian) for n = 3 assets and k = 2 views."""
import sympy as sp

n, k = 3, 2
tau = sp.symbols('tau', positive=True)
x   = sp.Matrix(sp.symbols('x1:4'))          # x = E[R]
Pi  = sp.Matrix(sp.symbols('Pi1:4'))
V   = sp.Matrix(sp.symbols('V1:3'))
phi = sp.Matrix(sp.symbols('phi1:3'))
P   = sp.Matrix(k, n, sp.symbols('p11 p12 p13 p21 p22 p23'))
s   = sp.symbols('s11 s12 s13 s22 s23 s33')
Sig = sp.Matrix([[s[0], s[1], s[2]], [s[1], s[3], s[4]], [s[2], s[4], s[5]]])
M = (tau*Sig).inv()
checks = {}

L = ((x-Pi).T*M*(x-Pi))[0] - 2*(phi.T*(P*x - V))[0]

# Step 1: FOCs
gx = sp.Matrix([sp.diff(L, xi) for xi in x])
checks['1. dL/dx = 2(tau Sig)^-1 (x - Pi) - 2 P^T phi'] = sp.simplify(gx - (2*M*(x-Pi) - 2*P.T*phi)) == sp.zeros(n,1)
gphi = sp.Matrix([sp.diff(L, p) for p in phi])
checks['1. dL/dphi = -2(Px - V)'] = sp.simplify(gphi + 2*(P*x - V)) == sp.zeros(k,1)

# Step 2: x(phi)
x_phi = Pi + tau*Sig*P.T*phi
checks['2. x = Pi + tau Sig P^T phi solves FOC (i)'] = sp.simplify(2*M*(x_phi-Pi) - 2*P.T*phi) == sp.zeros(n,1)

# Step 3: phi
A = P*tau*Sig*P.T
phi_sol = A.inv()*(V - P*Pi)
checks['3. phi = (P tau Sig P^T)^-1 (V - P Pi) satisfies P x = V'] = sp.simplify(P*x_phi.subs(dict(zip(phi, phi_sol))) - V) == sp.zeros(k,1)

# Step 4: result eq (10)
x_star = Pi + tau*Sig*P.T*A.inv()*(V - P*Pi)
checks['4. x(phi*) equals brief eq (10)'] = sp.simplify(x_phi.subs(dict(zip(phi, phi_sol))) - x_star) == sp.zeros(n,1)
checks['4. eq (10) satisfies the view constraint exactly'] = sp.simplify(P*x_star - V) == sp.zeros(k,1)

# Step 5: second order
H = sp.hessian(L, x)
checks['5. Hessian = 2 (tau Sig)^-1'] = sp.simplify(H - 2*M) == sp.zeros(n,n)

# Extra: views consistent with equilibrium -> no change
checks['Extra. V = P Pi gives E[R]* = Pi'] = sp.simplify(x_star.subs(dict(zip(V, P*Pi))) - Pi) == sp.zeros(n,1)

for kk, v in checks.items():
    print(f"[{'PASS' if v else 'FAIL'}] {kk}")
print(f"\n{sum(checks.values())}/{len(checks)} checks passed")
