function [turnover, driftedWeights] = oneWayTurnover(targetWeights, heldReturns)
%ONEWAYTURNOVER Drift-adjusted one-way turnover of a monthly rebalanced portfolio.
%
%   File:         oneWayTurnover.m
%   Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
%   Version:      PT_A2_2026_FRNBEN003_v1.0
%   Author:       Benjamin Franco (FRNBEN003)
%   Date:         2026-10-14
%   Purpose:      Convention of Gebbie, Lectures 004 and 005. The target
%                 weights w_k are held over month k and drift with that
%                 month's returns to
%                   d_k = w_k .* (1 + r_k) / (1 + w_k * r_k').
%                 The next rebalance trades from d_k to w_{k+1}, so
%                   turnover_{k+1} = 0.5 * sum(|w_{k+1} - d_k|).
%                 The first month has no earlier holding, so its turnover
%                 is NaN (the initial purchase is not counted).
%   Inputs:       targetWeights K x n weights set at each rebalance
%                 heldReturns   K x n asset returns over each holding month
%   Outputs:      turnover       K x 1 one-way turnover (first entry NaN)
%                 driftedWeights K x n weights at the end of each holding month
%   Dependencies: none (base MATLAB)

[K, n] = size(targetWeights);
assert(isequal(size(heldReturns), [K n]), 'oneWayTurnover:Size', 'Weights and returns must match.');

grossGrowth = targetWeights .* (1 + heldReturns);
driftedWeights = grossGrowth ./ sum(grossGrowth, 2);
turnover = nan(K, 1);
turnover(2:K) = 0.5 * sum(abs(targetWeights(2:K, :) - driftedWeights(1:K-1, :)), 2);

% ---- Diagnostics ----
assert(all(abs(sum(driftedWeights, 2) - 1) < 1e-12), 'oneWayTurnover:Drift', 'Drifted weights do not sum to one.');
assert(all(turnover(2:end) >= 0 & turnover(2:end) <= 1 + 1e-12), 'oneWayTurnover:Range', ...
    'One-way turnover must lie between 0 and 1 for long-only portfolios.');
end
