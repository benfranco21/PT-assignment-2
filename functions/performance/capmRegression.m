function capm = capmRegression(portfolioExcess, marketExcess, periodsPerYear)
%CAPMREGRESSION Jensen's alpha and CAPM beta by ordinary least squares.
%
%   File:         capmRegression.m
%   Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
%   Version:      PT_A2_2026_FRNBEN003_v1.0
%   Author:       Benjamin Franco (FRNBEN003)
%   Date:         2026-10-14
%   Purpose:      Fit the CAPM time-series regression
%                   r_p,t - r_f,t = alpha + beta (r_m,t - r_f,t) + e_t
%                 by OLS. alpha is Jensen's alpha (per period, also
%                 annualised as periodsPerYear * alpha), beta is the CAPM
%                 beta. Standard errors use s^2 = SSR / (T - 2) and
%                 (X'X)^-1, the classical OLS formulas.
%   Inputs:       portfolioExcess  T x 1 portfolio return minus risk-free
%                 marketExcess     T x 1 market (ALSI) return minus risk-free
%                 periodsPerYear   12 for monthly data
%   Outputs:      capm struct with .Alpha, .AlphaAnnual, .Beta, .TAlpha,
%                 .TBeta, .SEAlpha, .SEBeta, .R2, .Observations
%   Dependencies: none (base MATLAB)

y = portfolioExcess(:);
x = marketExcess(:);
T = numel(y);
assert(numel(x) == T && T > 2, 'capmRegression:Size', 'Need two equal columns with T > 2.');
assert(all(isfinite([y; x])), 'capmRegression:NonFinite', 'Returns must be finite.');

X = [ones(T, 1), x];
b = X \ y;
residuals = y - X * b;
ssr = residuals' * residuals;
sst = sum((y - mean(y)).^2);
s2 = ssr / (T - 2);
se = sqrt(diag(s2 * ((X' * X) \ eye(2))));

capm = struct();
capm.Alpha = b(1);
capm.AlphaAnnual = periodsPerYear * b(1);
capm.Beta = b(2);
capm.SEAlpha = se(1);
capm.SEBeta = se(2);
capm.R2 = 1 - ssr / sst;
capm.Observations = T;
if s2 > 1e-14 * sst / T
    capm.TAlpha = b(1) / se(1);
    capm.TBeta = b(2) / se(2);
else
    % Perfect fit (for example the market regressed on itself): t-stats undefined.
    capm.TAlpha = NaN;
    capm.TBeta = NaN;
end

% ---- Diagnostics ----
assert(abs(mean(residuals)) < 1e-12, 'capmRegression:Residuals', 'OLS residuals do not average to zero.');
assert(abs(x' * residuals) < 1e-10, 'capmRegression:Orthogonality', 'Residuals are not orthogonal to the market.');
end
