"""
File:         verify_q3_2_1.py
Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
Version:      PT_A2_2026_FRNBEN003_v1.0
Author:       Benjamin Franco (FRNBEN003)
Date:         2026-10-14
Purpose:      Symbolic (SymPy) verification of Q3.2.1: product of the two Gaussian densities equals
  a constant times the kernel of brief eq (12), n = 3 assets and k = 2 views.
Inputs:       None (all quantities are symbolic or fixed-seed exact rationals).
Outputs:      One PASS/FAIL line per check and a "n/N checks passed" summary on stdout.
Dependencies: Python 3.9+, sympy==1.14.0, mpmath==1.3.0 (see requirements.txt).
"""
"""SymPy check of Q3.2.1: product of the two Gaussian densities = constant x eq (12) kernel (n = 3, k = 2)."""
import sympy as sp

n, k = 3, 2
tau = sp.symbols('tau', positive=True)
x   = sp.Matrix(sp.symbols('x1:4'))          # x = E[R]
Pi  = sp.Matrix(sp.symbols('Pi1:4'))
V   = sp.Matrix(sp.symbols('V1:3'))
P   = sp.Matrix(k, n, sp.symbols('p11 p12 p13 p21 p22 p23'))
s   = sp.symbols('s11 s12 s13 s22 s23 s33')
Sig = sp.Matrix([[s[0], s[1], s[2]], [s[1], s[3], s[4]], [s[2], s[4], s[5]]])
om  = sp.symbols('om1 om2', positive=True)
Om  = sp.diag(*om)                            # diagonal, positive (S&S A1)

def logN(z, m, S, d):
    return -sp.Rational(d, 2)*sp.log(2*sp.pi) - sp.log(S.det())/2 - ((z-m).T*S.inv()*(z-m))[0]/2

log_lik   = logN(Pi, x, tau*Sig, n)           # assumption ii: Pi | x ~ N(x, tau Sig)
log_prior = logN(P*x, V, Om, k)               # assumption i:  P x ~ N(V, Omega)
log_eq12_kernel = -((Pi-x).T*(tau*Sig).inv()*(Pi-x))[0]/2 - ((P*x-V).T*Om.inv()*(P*x-V))[0]/2

diff = sp.simplify(log_lik + log_prior - log_eq12_kernel)   # should be log k: free of x
checks = {
  '3.2.1 log(lik x prior) - log(eq 12 kernel) does not depend on E[R]': all(sp.simplify(sp.diff(diff, xi)) == 0 for xi in x),
  '3.2.1 the leftover is -(n+k)/2 log 2pi - 1/2 log|tau Sig| - 1/2 log|Omega|':
      sp.simplify(diff - (-sp.Rational(n+k,2)*sp.log(2*sp.pi) - sp.log((tau*Sig).det())/2 - sp.log(Om.det())/2)) == 0,
  '3.2.1 (Pi - x)^T M (Pi - x) = (x - Pi)^T M (x - Pi)':
      sp.simplify(((Pi-x).T*Sig.inv()*(Pi-x))[0] - ((x-Pi).T*Sig.inv()*(x-Pi))[0]) == 0,
}
for kk, v in checks.items():
    print(f"[{'PASS' if v else 'FAIL'}] {kk}")
print(f"\n{sum(checks.values())}/{len(checks)} checks passed")
