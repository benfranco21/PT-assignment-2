"""
File:         verify_q3_2_2.py
Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
Version:      PT_A2_2026_FRNBEN003_v1.0
Author:       Benjamin Franco (FRNBEN003)
Date:         2026-10-14
Purpose:      Symbolic and exact-rational (SymPy) verification of Q3.2.2 and Q3.2.3: expansion,
  completing the square, eqs (13)-(14), Woodbury identity and the Omega -> 0 limit.
Inputs:       None (all quantities are symbolic or fixed-seed exact rationals).
Outputs:      One PASS/FAIL line per check and a "n/N checks passed" summary on stdout.
Dependencies: Python 3.9+, sympy==1.14.0, mpmath==1.3.0 (see requirements.txt).
"""
"""SymPy check of Q3.2.2 and Q3.2.3.
Part A: fully symbolic (n = 3 assets, k = 2 views) for the expansion and grouping.
Part B: fully symbolic (n = 2, k = 1) for every step that needs a matrix inverse.
Part C: exact rational arithmetic (n = 4, k = 2, random SPD Sigma, random P) for the same inverse steps."""
import sympy as sp, random

def report(name, ok):
    print(f"[{'PASS' if ok else 'FAIL'}] {name}", flush=True); return ok
res = []

def setup(n, k, symbolic=True, seed=0):
    tau = sp.symbols('tau', positive=True)
    x = sp.Matrix(sp.symbols(f'x1:{n+1}'))
    if symbolic:
        Pi = sp.Matrix(sp.symbols(f'Pi1:{n+1}')); V = sp.Matrix(sp.symbols(f'V1:{k+1}'))
        P = sp.Matrix(k, n, sp.symbols(f'p1:{k*n+1}'))
        sy = sp.symbols(f's1:{n*(n+1)//2+1}'); Sig = sp.zeros(n, n); it = iter(sy)
        for i in range(n):
            for j in range(i, n):
                Sig[i, j] = Sig[j, i] = next(it)
        om = sp.symbols(f'om1:{k+1}', positive=True)
    else:
        random.seed(seed); R = lambda: sp.Rational(random.randint(-9, 9), random.randint(1, 5))
        Pi = sp.Matrix(n, 1, lambda i, j: R()); V = sp.Matrix(k, 1, lambda i, j: R())
        P = sp.Matrix(k, n, lambda i, j: R())
        B = sp.Matrix(n, n, lambda i, j: R()); Sig = B*B.T + sp.eye(n)          # SPD
        om = [sp.Rational(random.randint(1, 9), 10) for _ in range(k)]
    Om = sp.diag(*om); T = tau*Sig
    return dict(n=n, k=k, tau=tau, x=x, Pi=Pi, V=V, P=P, Sig=Sig, Om=Om, om=om, T=T)

# ---------- Part A: expansion and grouping (no inverses needed) ----------
d = setup(3, 2)
x, Pi, V, P, n = d['x'], d['Pi'], d['V'], d['P'], d['n']
Ti = sp.MatrixSymbol('W', n, n).as_explicit()          # stands for (tau Sigma)^-1, any symmetric matrix
Ti = (Ti + Ti.T)/2
Oi = sp.diag(*sp.symbols('q1:3', positive=True))       # stands for Omega^-1, diagonal
Q1 = ((Pi-x).T*Ti*(Pi-x))[0]; Q2 = ((P*x-V).T*Oi*(P*x-V))[0]
H = Ti + P.T*Oi*P; C = Ti*Pi + P.T*Oi*V; A = (V.T*Oi*V)[0] + (Pi.T*Ti*Pi)[0]
res.append(report('A. Q1 = x^T M x - 2 Pi^T M x + Pi^T M Pi', sp.expand(Q1 - ((x.T*Ti*x)[0] - 2*(Pi.T*Ti*x)[0] + (Pi.T*Ti*Pi)[0])) == 0))
res.append(report('A. Q2 = x^T P^T O^-1 P x - 2 V^T O^-1 P x + V^T O^-1 V', sp.expand(Q2 - ((x.T*P.T*Oi*P*x)[0] - 2*(V.T*Oi*P*x)[0] + (V.T*Oi*V)[0])) == 0))
res.append(report('A. Q1 + Q2 = x^T H x - 2 C^T x + A', sp.expand(Q1 + Q2 - ((x.T*H*x)[0] - 2*(C.T*x)[0] + A)) == 0))
res.append(report('A. H is symmetric', sp.expand(H - H.T) == sp.zeros(n, n)))
res.append(report('A. 3.2.3: Hessian of (Q1+Q2)/2 is H', sp.expand(sp.hessian((Q1+Q2)/2, x) - H) == sp.zeros(n, n)))

# ---------- Parts B and C: everything that needs inverses ----------
def inverse_checks(tag, d):
    x, Pi, V, P, Om, T, om, n, k = d['x'], d['Pi'], d['V'], d['P'], d['Om'], d['T'], d['om'], d['n'], d['k']
    Ti, Oi = T.inv(), Om.inv()
    Q = ((Pi-x).T*Ti*(Pi-x))[0] + ((P*x-V).T*Oi*(P*x-V))[0]
    H = Ti + P.T*Oi*P; C = Ti*Pi + P.T*Oi*V; A = (V.T*Oi*V)[0] + (Pi.T*Ti*Pi)[0]
    Hi = H.inv(); m = Hi*C
    sq = ((x-m).T*H*(x-m))[0] + A - (C.T*Hi*C)[0]
    res.append(report(f'{tag}. completing the square: x^T H x - 2C^T x + A = (x-H^-1C)^T H (x-H^-1C) + A - C^T H^-1 C',
                      sp.simplify((x.T*H*x)[0] - 2*(C.T*x)[0] + A - sq) == 0))
    res.append(report(f'{tag}. leftover A - C^T H^-1 C contains no x', all(sp.diff(A - (C.T*Hi*C)[0], xi) == 0 for xi in x)))
    res.append(report(f'{tag}. eq (13) H^-1 C is where the exponent gradient is zero',
                      sp.simplify(sp.Matrix([sp.diff(Q, xi) for xi in x]).subs(dict(zip(x, m)))) == sp.zeros(n, 1)))
    eq14 = Pi + T*P.T*(P*T*P.T + Om).inv()*(V - P*Pi)
    res.append(report(f'{tag}. Woodbury identity: H^-1 P^T O^-1 = tS P^T (P tS P^T + O)^-1',
                      sp.simplify(Hi*P.T*Oi - T*P.T*(P*T*P.T + Om).inv()) == sp.zeros(n, k)))
    res.append(report(f'{tag}. eq (14) equals eq (13)', sp.simplify(m - eq14) == sp.zeros(n, 1)))
    alt = T - T*P.T*(P*T*P.T + Om).inv()*P*T
    res.append(report(f'{tag}. 3.2.3 Woodbury form: H^-1 = tS - tS P^T (P tS P^T + O)^-1 P tS', sp.simplify(Hi - alt) == sp.zeros(n, n)))
    eq10 = Pi + T*P.T*(P*T*P.T).inv()*(V - P*Pi)
    eq14_of = lambda O: Pi + T*P.T*(P*T*P.T + O).inv()*(V - P*Pi)
    res.append(report(f'{tag}. eq (14) with Omega = 0 equals eq (10)', sp.simplify(eq14_of(sp.zeros(k, k)) - eq10) == sp.zeros(n, 1)))
    eps = sp.symbols('epsilon', positive=True)
    lim = sp.Matrix([sp.limit(sp.simplify(e), eps, 0) for e in eq14_of(eps*Om)])
    res.append(report(f'{tag}. limit as Omega = eps*Omega0, eps -> 0, of eq (14) equals eq (10)', sp.simplify(lim - eq10) == sp.zeros(n, 1)))

inverse_checks('B', setup(2, 1, symbolic=True))
inverse_checks('C', setup(4, 2, symbolic=False, seed=7))
print(f"\n{sum(res)}/{len(res)} checks passed")
