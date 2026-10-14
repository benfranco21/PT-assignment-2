function w = blWeights(Sigma, expectedReturns, gamma)
%BLWEIGHTS Fully invested mean-variance weights from the separation theorem.
%
%   File:         blWeights.m
%   Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
%   Version:      PT_A2_2026_FRNBEN003_v1.0
%   Author:       Benjamin Franco (FRNBEN003)
%   Date:         2026-10-14
%   Purpose:      Evaluate equation (16) of the brief (Part I, Questions 1
%                 and 4):
%                   w = Sigma^-1 1 / (1' Sigma^-1 1)
%                       + (1/gamma) Sigma^-1 ( m - 1 (1' Sigma^-1 m)/(1' Sigma^-1 1) )
%                 With m = Pi this returns the benchmark that Pi was reverse
%                 engineered from. With m = E[R]* it returns the
%                 Black-Litterman weights. Linear solves are used instead of
%                 an explicit inverse, as in Gebbie (Lecture 003).
%   Inputs:       Sigma           n x n return covariance (symmetric, positive definite)
%                 expectedReturns n x 1 or 1 x n expected returns m
%                 gamma           positive scalar risk aversion
%   Outputs:      w               1 x n weights, sum(w) = 1 (no sign restriction)
%   Dependencies: none (base MATLAB)

m = expectedReturns(:);
n = numel(m);
assert(isequal(size(Sigma), [n n]), 'blWeights:Size', 'Sigma must be n x n.');
assert(isscalar(gamma) && gamma > 0, 'blWeights:Gamma', 'gamma must be positive.');

one = ones(n, 1);
z = Sigma \ one;            % Sigma^-1 1
C = one' * z;               % 1' Sigma^-1 1  (> 0)
y = Sigma \ m;              % Sigma^-1 m
A = one' * y;               % 1' Sigma^-1 m

minimumVariance = z / C;                 % benchmark (MVP) fund
tilt = (y - (A / C) * z) / gamma;        % zero-cost tilt
w = (minimumVariance + tilt)';

assert(abs(sum(w) - 1) < 1e-10, 'blWeights:Budget', 'Weights do not sum to one.');
assert(abs(sum(tilt)) < 1e-10, 'blWeights:ZeroCost', 'Tilt is not zero cost.');
end
