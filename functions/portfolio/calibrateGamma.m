function [gamma, details] = calibrateGamma(windowReturns, benchmarkWeights)
%CALIBRATEGAMMA Risk aversion implied by the benchmark over one estimation window.
%
%   File:         calibrateGamma.m
%   Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
%   Version:      PT_A2_2026_FRNBEN003_v1.0
%   Author:       Benjamin Franco (FRNBEN003)
%   Date:         2026-10-14
%   Purpose:      The equilibrium returns are Pi = gamma * Sigma * wB. The
%                 benchmark's own equilibrium return is then
%                   wB' * Pi = gamma * (wB' * Sigma * wB).
%                 Setting this equal to the benchmark's average return over
%                 the window gives
%                   gamma = mean(benchmark return) / variance(benchmark return),
%                 the usual Black-Litterman calibration (Black and Litterman
%                 1992, Section V) with total returns, as in Gebbie's Lecture
%                 003 where Pi has no risk-free intercept. It uses only data
%                 inside the window, so it involves no look-ahead.
%   Inputs:       windowReturns    T x n simple returns (the estimation window)
%                 benchmarkWeights 1 x n benchmark weights, sum to 1
%   Outputs:      gamma            positive scalar
%                 details          struct with .BenchmarkMean, .BenchmarkVariance,
%                                  .ImpliedPiBenchmark (all monthly)
%   Dependencies: none (base MATLAB)

wB = benchmarkWeights(:)';
assert(size(windowReturns, 2) == numel(wB), 'calibrateGamma:Size', ...
    'windowReturns must have one column per asset.');
Sigma = cov(windowReturns);
benchmarkReturns = windowReturns * wB';
benchmarkMean = mean(benchmarkReturns);
benchmarkVariance = wB * Sigma * wB';

gamma = benchmarkMean / benchmarkVariance;

details = struct();
details.BenchmarkMean = benchmarkMean;
details.BenchmarkVariance = benchmarkVariance;
details.ImpliedPiBenchmark = wB * (gamma * Sigma * wB');

% ---- Diagnostics ----
assert(isfinite(gamma) && gamma > 0, 'calibrateGamma:NotPositive', ...
    'Implied risk aversion is not positive (benchmark mean %.4g).', benchmarkMean);
assert(abs(details.ImpliedPiBenchmark - benchmarkMean) < 1e-12, ...
    'calibrateGamma:Check', 'Calibrated Pi does not reproduce the benchmark mean.');
end
