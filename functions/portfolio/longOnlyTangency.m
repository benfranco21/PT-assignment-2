function [w, sharpe] = longOnlyTangency(mu, Sigma, riskFree)
%LONGONLYTANGENCY Long-only, fully invested maximum Sharpe ratio portfolio, solved exactly.
%
%   File:         longOnlyTangency.m
%   Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
%   Version:      PT_A2_2026_FRNBEN003_v1.0
%   Author:       Benjamin Franco (FRNBEN003)
%   Date:         2026-10-14
%   Purpose:      Rebuild the Assignment 1 rolling tangency portfolio without
%                 fmincon (Optimization Toolbox), so Assignment 2 needs only
%                 base MATLAB. Maximising the Sharpe ratio with w >= 0 and
%                 sum(w) = 1 is the same as solving
%                   min y' Sigma y  subject to  (mu - rf)' y = 1, y >= 0
%                 and setting w = y / sum(y). At the optimum, on its support S
%                 the KKT conditions give y_S proportional to
%                 Sigma_SS^-1 (mu - rf)_S with all entries positive. So I
%                 try every support S (2^n - 1 = 511 sets for n = 9), keep
%                 the sets where that solution is positive, and return the
%                 one with the largest Sharpe ratio. This is exact, with no
%                 tolerance or starting point.
%   Inputs:       mu        n x 1 or 1 x n mean returns of the window
%                 Sigma     n x n covariance of the window
%                 riskFree  scalar mean risk-free return of the window
%   Outputs:      w         1 x n weights, non-negative, sum to 1
%                 sharpe    per-period Sharpe ratio of w on (mu, Sigma)
%   Dependencies: none (base MATLAB)

excess = mu(:) - riskFree;
n = numel(excess);
assert(isequal(size(Sigma), [n n]), 'longOnlyTangency:Size', 'Sigma must be n x n.');
assert(any(excess > 0), 'longOnlyTangency:NoPositiveExcess', ...
    'No asset has a positive excess mean, so no long-only tangency portfolio exists.');

w = nan(1, n);
sharpe = -Inf;
for mask = 1:(2^n - 1)
    support = logical(bitget(mask, 1:n));
    y = Sigma(support, support) \ excess(support);
    if all(y > 0)
        candidate = zeros(1, n);
        candidate(support) = y' / sum(y);
        candidateSharpe = (candidate * excess) / sqrt(candidate * Sigma * candidate');
        if candidateSharpe > sharpe
            sharpe = candidateSharpe;
            w = candidate;
        end
    end
end

% ---- Diagnostics ----
assert(all(isfinite(w)), 'longOnlyTangency:NotFound', 'No feasible support found.');
assert(min(w) >= 0 && abs(sum(w) - 1) < 1e-12, 'longOnlyTangency:Budget', ...
    'Weights are not long-only and fully invested.');
end
