function out = applyActiveControls(benchmarkWeights, rawWeights, Sigma, teCeiling, periodsPerYear)
%APPLYACTIVECONTROLS Scale active bets to a tracking-error ceiling and to no short selling.
%
%   File:         applyActiveControls.m
%   Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
%   Version:      PT_A2_2026_FRNBEN003_v1.0
%   Author:       Benjamin Franco (FRNBEN003)
%   Date:         2026-10-14
%   Purpose:      Follows the controls in Gebbie, Lecture 003 (Black-Litterman
%                 section). The active bets a = rawWeights - benchmark are
%                 (1) scaled down so the annualised ex-ante tracking error is
%                 at most teCeiling, then (2) scaled down again, if needed,
%                 until no total weight is negative. Both steps multiply the
%                 whole active vector by one number, so the direction of the
%                 bets from equation (16) is kept and the active weights
%                 still sum to zero. No optimiser is used.
%   Inputs:       benchmarkWeights 1 x n, non-negative, sums to 1
%                 rawWeights       1 x n, sums to 1 (from blWeights)
%                 Sigma            n x n monthly return covariance
%                 teCeiling        annualised tracking-error ceiling (e.g. 0.10)
%                 periodsPerYear   12 for monthly data
%   Outputs:      out struct with fields
%                   .Weights        final 1 x n weights
%                   .Active         final 1 x n active weights
%                   .RawTE          annualised TE before any scaling
%                   .TE             annualised TE after scaling
%                   .TEScale        factor from the TE ceiling (<= 1)
%                   .NoShortScale   factor from the no-short rule (<= 1)
%                   .TEBinding      true if the TE ceiling reduced the bets
%                   .NoShortBinding true if the no-short rule reduced the bets
%   Dependencies: none (base MATLAB)

wB = benchmarkWeights(:)';
rawActive = rawWeights(:)' - wB;
assert(all(wB >= 0) && abs(sum(wB) - 1) < 1e-12, 'Controls:Benchmark', ...
    'Benchmark must be non-negative and sum to one.');

annualTE = @(a) sqrt(periodsPerYear * (a * Sigma * a'));

% (1) tracking-error ceiling
rawTE = annualTE(rawActive);
if rawTE > sqrt(eps)
    teScale = min(1, teCeiling / rawTE);
else
    teScale = 0;
end
active = teScale * rawActive;

% (2) no short selling: largest k in [0,1] with wB + k*active >= 0
negative = active < 0;
if any(negative)
    noShortScale = max(0, min(1, min(-wB(negative) ./ active(negative))));
else
    noShortScale = 1;
end
active = noShortScale * active;

out = struct();
out.Active = active;
out.Weights = wB + active;
out.RawTE = rawTE;
out.TE = annualTE(active);
out.TEScale = teScale;
out.NoShortScale = noShortScale;
out.TEBinding = teScale < 1 - 1e-12;
out.NoShortBinding = noShortScale < 1 - 1e-12;

% ---- Diagnostics ----
assert(min(out.Weights) >= -1e-12, 'Controls:Short', 'A weight is negative.');
assert(abs(sum(out.Weights) - 1) < 1e-12, 'Controls:Budget', 'Weights do not sum to one.');
assert(abs(sum(out.Active)) < 1e-12, 'Controls:ZeroCost', 'Active weights do not sum to zero.');
assert(out.TE <= teCeiling + 1e-12, 'Controls:TE', 'Tracking error is above the ceiling.');
end
