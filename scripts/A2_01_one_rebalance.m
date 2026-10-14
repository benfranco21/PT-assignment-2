%[text] # STA4028Z Portfolio Theory, Assignment 2
%[text] ## Part II, Step 1: one Black-Litterman rebalance, worked by hand
%[text] **File:** `A2_01_one_rebalance.m`
%[text] **Version:** `PT_A2_2026_FRNBEN003_v1.0`
%[text] **Author:** Benjamin Franco (FRNBEN003)
%[text] **Date:** 2026-10-14
%[text] **Purpose:** Build the Black-Litterman portfolio for a single decision date (the first rebalance of the Assignment 1 rolling window) and print every intermediate quantity: covariance, equilibrium returns, views, posterior, raw weights, tracking-error and no-short controls, and the next month's realised return. The full rolling backtest in the next script repeats exactly these steps every month.
%[text] **Inputs:** data/raw/PT-DATA-ALBI-JIBAR-JSEIND-Daily-1994-2017.xlsx (through loadA2Data).
%[text] **Outputs:** printed tables, `outputs/figures/A2_01_expected_returns.png`, `outputs/figures/A2_01_weights.png`
%[text] **Dependencies:** base MATLAB only. functions/data/loadA2Data.m, functions/portfolio/blWeights.m, functions/portfolio/applyActiveControls.m, and Tim Gebbie's blackLittermanPosterior.m and data functions (BSD-3-Clause, copied unchanged).
%[text] ### Set up: find the project folder and add the functions to the path
%[text] This block lets the script run on its own from any current folder.
projectRoot = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('loadA2Data'))
    run(fullfile(projectRoot, 'startup.m'));
end
rng(20261014, 'twister');
executionTimestamp = datetime('now')
figureFolder = fullfile(projectRoot, 'outputs', 'figures');
if ~isfolder(figureFolder), mkdir(figureFolder); end
%[text] ## 1. Load the monthly data (same sample and universe as Assignment 1)
A2 = loadA2Data(projectRoot);
tickers = A2.RiskyTickers;
n = numel(tickers);
h = A2.h;              % 87-month rolling window, as in A1
periodsPerYear = 12;
%[text] ## 2. Choose the decision date
%[text] The first rebalance uses returns 1 to h (the estimation window) and the weights are held over month h+1. This is the same first out-of-sample month as Assignment 1.
t = h;
windowRows = t-h+1:t;
fprintf('Decision date: %s. Estimation window: %s to %s (%d months). Holding month: %s.\n', ...
    string(A2.Dates(t), 'MMM yyyy'), string(A2.Dates(windowRows(1)), 'MMM yyyy'), ...
    string(A2.Dates(windowRows(end)), 'MMM yyyy'), numel(windowRows), string(A2.Dates(t+1), 'MMM yyyy'));
%[text] ## 3. Estimate risk from the window
%[text] $\Sigma$ is the sample covariance of monthly simple returns over the window.
Sigma = cov(A2.R(windowRows, :));
riskTable = table(tickers', 100*sqrt(periodsPerYear*diag(Sigma)), ...
    'VariableNames', {'Asset', 'AnnualVolatility_pct'})
%[text] ## 4. The benchmark and the equilibrium returns
%[text] The benchmark (strategic portfolio) is equal weight. The equilibrium returns are reverse engineered from it: $\Pi = \gamma \Sigma \omega_B$. If the investor has no views, the separation theorem (equation 16 with $\Pi$ in place of $\mathbb{E}[R]^*$) must give back the benchmark exactly. That is the first check.
wB = ones(1, n) / n;    % equal-weight benchmark
gamma = 3;              % PROVISIONAL risk aversion (Tim's Lecture 003 value). Chosen properly by the grid in a later script.
Pi = gamma * Sigma * wB';
wFromPi = blWeights(Sigma, Pi, gamma);
fprintf('Check: weights from Pi reproduce the benchmark, max difference = %.2e\n', max(abs(wFromPi - wB)));
assert(max(abs(wFromPi - wB)) < 1e-10, 'Equilibrium returns do not reproduce the benchmark.');
%[text] ## 5. The views
%[text] One absolute view per asset ($P = I$). The view value is the asset's average return over the last 12 months, in the spirit of the 12-month views in Gebbie's Lecture 003. Confidence $c = 0.5$ and $\tau = 1/h$, also following Lecture 003, with
%[text] $\Omega = \frac{1-c}{c}\,\mathrm{diag}(P\tau\Sigma P')$.
viewLookback = 12;
P = eye(n);
V = P * mean(A2.R(t-viewLookback+1:t, :), 1)';
tau = 1 / h;
c = 0.50;
priorViewCov = P * (tau*Sigma) * P';
viewRidge = max(eps, max(diag(priorViewCov)) * 1e-12);   % as in Lecture 003
Omega = ((1-c)/c) * diag(diag(priorViewCov)) + viewRidge*eye(n);
%[text] ## 6. The Black-Litterman posterior mean
%[text] Gebbie's function evaluates equation (14). I also evaluate equation (13) directly to show the two forms from Part I give the same answer on real data.
[ERstar, postMeanCov] = blackLittermanPosterior(Pi, Sigma, tau, P, V, Omega);
ERstar = ERstar(:);
H = inv(tau*Sigma) + P' / Omega * P;
ERstar13 = H \ ((tau*Sigma) \ Pi + P' / Omega * V);
fprintf('Check: equation (13) and equation (14) agree, max difference = %.2e\n', max(abs(ERstar13 - ERstar)));
assert(max(abs(ERstar13 - ERstar)) < 1e-10, 'Equations (13) and (14) disagree.');
returnsTable = table(tickers', 100*periodsPerYear*Pi, 100*periodsPerYear*V, 100*periodsPerYear*ERstar, ...
    'VariableNames', {'Asset', 'Equilibrium_Pi_pa', 'View_V_pa', 'Posterior_ER_pa'})
%[text] The posterior sits between the equilibrium and the views. Because $\Omega$ is proportional to $P\tau\Sigma P'$, with $c = 0.5$ each posterior value is roughly half way between $\Pi$ and $V$, adjusted through the correlations.
figure
bar(categorical(tickers, tickers), 100*periodsPerYear*[Pi, V, ERstar])
ylabel('Expected return (% per year)')
title(sprintf('Equilibrium, views and posterior at %s', string(A2.Dates(t), 'MMM yyyy')))
legend({'Equilibrium \Pi', 'View V (12-month mean)', 'Posterior E[R]^*'}, 'Location', 'best')
grid on
exportgraphics(gcf, fullfile(figureFolder, 'A2_01_expected_returns.png'), 'Resolution', 200);
%[text] ## 7. Raw Black-Litterman weights (equation 16)
wRaw = blWeights(Sigma, ERstar, gamma);
%[text] ## 8. Apply the controls: tracking-error ceiling, then no short selling
%[text] Both controls shrink the active bets $\omega - \omega_B$ by a single factor, so the direction of the bets from equation (16) is kept (Lecture 003).
teCeiling = 0.10;   % top of the brief's 3% to 10% range
ctrl = applyActiveControls(wB, wRaw, Sigma, teCeiling, periodsPerYear);
weightsTable = table(tickers', 100*wB', 100*wRaw', 100*ctrl.Weights', 100*ctrl.Active', ...
    'VariableNames', {'Asset', 'Benchmark_pct', 'RawBL_pct', 'FinalBL_pct', 'Active_pct'})
fprintf(['Raw tracking error %.2f%% p.a. | TE scale %.3f | no-short scale %.3f | ' ...
    'final tracking error %.2f%% p.a.\n'], 100*ctrl.RawTE, ctrl.TEScale, ctrl.NoShortScale, 100*ctrl.TE);
figure
bar(categorical(tickers, tickers), 100*[wB; ctrl.Weights]')
ylabel('Weight (%)')
title(sprintf('Benchmark and Black-Litterman weights held over %s', string(A2.Dates(t+1), 'MMM yyyy')))
legend({'Equal-weight benchmark', 'Black-Litterman (after controls)'}, 'Location', 'best')
grid on
exportgraphics(gcf, fullfile(figureFolder, 'A2_01_weights.png'), 'Resolution', 200);
%[text] ## 9. What the fund earned over the next month
%[text] The weights set at the decision date earn the returns realised over the following month. This is the step the backtest loop repeats.
nextReturns = A2.R(t+1, :);
portfolioReturn = ctrl.Weights * nextReturns';
benchmarkReturn = wB * nextReturns';
fprintf('Month %s: Black-Litterman %.2f%%, benchmark %.2f%%, active %.2f%%\n', ...
    string(A2.Dates(t+1), 'MMM yyyy'), 100*portfolioReturn, 100*benchmarkReturn, 100*(portfolioReturn - benchmarkReturn));
fprintf('A2_01_one_rebalance completed.\n');

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":32}
%---
