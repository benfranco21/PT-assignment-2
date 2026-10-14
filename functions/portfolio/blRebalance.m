function step = blRebalance(windowReturns, viewReturns, benchmarkWeights, gamma, settings)
%BLREBALANCE One Black-Litterman rebalance: equilibrium, views, posterior, weights, controls.
%
%   File:         blRebalance.m
%   Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
%   Version:      PT_A2_2026_FRNBEN003_v1.0
%   Author:       Benjamin Franco (FRNBEN003)
%   Date:         2026-10-14
%   Purpose:      The same steps as scripts/A2_01_one_rebalance.m, packed
%                 into one function so the gamma grid (A2_02) and the
%                 backtest (A2_03) use identical code:
%                   1. Sigma = sample covariance of the window
%                   2. Pi = gamma * Sigma * wB              (reverse optimisation)
%                   3. P = I, V = mean of viewReturns       (absolute views)
%                   4. Omega = ((1-c)/c) diag(P tau Sigma P') + ridge  (Lecture 003)
%                   5. E[R]* from blackLittermanPosterior   (equation 14)
%                   6. raw weights from equation (16)        (blWeights)
%                   7. tracking-error ceiling, then no short selling
%   Inputs:       windowReturns    h x n returns of the estimation window
%                 viewReturns      L x n returns used to form the views (last L months)
%                 benchmarkWeights 1 x n
%                 gamma            positive scalar risk aversion
%                 settings         struct with .Tau, .Confidence, .TECeiling, .PeriodsPerYear
%   Outputs:      step struct with .Sigma, .Pi, .V, .ERstar, .RawWeights and
%                 the fields of applyActiveControls (.Weights, .Active, .RawTE,
%                 .TE, .TEScale, .NoShortScale, .TEBinding, .NoShortBinding)
%   Dependencies: blWeights.m, applyActiveControls.m, and Gebbie's
%                 blackLittermanPosterior.m (BSD-3-Clause, copied unchanged)

wB = benchmarkWeights(:)';
n = numel(wB);
assert(size(windowReturns, 2) == n && size(viewReturns, 2) == n, ...
    'blRebalance:Size', 'Return matrices must have one column per asset.');

Sigma = cov(windowReturns);
Pi = gamma * Sigma * wB';

P = eye(n);
V = P * mean(viewReturns, 1)';
tau = settings.Tau;
c = settings.Confidence;
priorViewCov = P * (tau * Sigma) * P';
viewRidge = max(eps, max(diag(priorViewCov)) * 1e-12);
Omega = ((1 - c) / c) * diag(diag(priorViewCov)) + viewRidge * eye(n);

ERstar = blackLittermanPosterior(Pi, Sigma, tau, P, V, Omega);
ERstar = ERstar(:);

rawWeights = blWeights(Sigma, ERstar, gamma);
step = applyActiveControls(wB, rawWeights, Sigma, settings.TECeiling, settings.PeriodsPerYear);

step.Sigma = Sigma;
step.Pi = Pi;
step.V = V;
step.ERstar = ERstar;
step.RawWeights = rawWeights;

% ---- Diagnostics ----
assert(all(isfinite(ERstar)), 'blRebalance:Posterior', 'Posterior mean is not finite.');
assert(rcond(Sigma) > 1e-12, 'blRebalance:Sigma', 'Window covariance is close to singular.');
end
