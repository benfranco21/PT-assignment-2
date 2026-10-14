%[text] # STA4028Z Portfolio Theory, Assignment 2
%[text] ## Part II, Step 3: the rolling Black-Litterman backtest
%[text] **File:** `A2_03_backtest.m`
%[text] **Version:** `PT_A2_2026_FRNBEN003_v1.0`
%[text] **Author:** Benjamin Franco (FRNBEN003)
%[text] **Date:** 2026-10-14
%[text] **Purpose:** Run the Black-Litterman fund every month over the 58 out-of-sample months, using the same rolling 87-month window as Assignment 1, and compare it with the equal-weight benchmark, the Assignment 1 rolling long-only tangency portfolio and the ALSI. Report equity curves, weights, drift-adjusted turnover, Sharpe ratios, Jensen's alpha and CAPM beta against the ALSI, and tracking error and information ratio against the benchmark.
%[text] **Inputs:** data/raw/PT-DATA-ALBI-JIBAR-JSEIND-Daily-1994-2017.xlsx (through loadA2Data).
%[text] **Outputs:** printed tables; `outputs/tables/A2_03_performance.csv`, `A2_03_monthly_returns.csv`, `A2_03_weights_BL.csv`, `A2_03_weights_tangency.csv`; figures `outputs/figures/A2_03_equity_curves.png`, `A2_03_weights_bars.png`, `A2_03_weights_over_time.png`, `A2_03_risk_and_turnover.png`
%[text] **Dependencies:** base MATLAB only. loadA2Data, calibrateGamma, blRebalance (with blWeights, applyActiveControls, Gebbie's blackLittermanPosterior), longOnlyTangency, oneWayTurnover, capmRegression.
%[text] ### Set up: find the project folder and add the functions to the path
projectRoot = fileparts(fileparts(mfilename('fullpath')));
if isempty(which('loadA2Data'))
    run(fullfile(projectRoot, 'startup.m'));
end
rng(20261014, 'twister');
executionTimestamp = datetime('now')
figureFolder = fullfile(projectRoot, 'outputs', 'figures');
tableFolder = fullfile(projectRoot, 'outputs', 'tables');
if ~isfolder(figureFolder), mkdir(figureFolder); end
if ~isfolder(tableFolder), mkdir(tableFolder); end
%[text] ## 1. Data and settings
%[text] All settings are fixed before the loop and were motivated in Steps 1 and 2: equal-weight benchmark, absolute views from 12-month mean returns, $c = 0.5$, $\tau = 1/h$, a 5% tracking-error cap, no short selling, and $\gamma$ calibrated on the first window only.
A2 = loadA2Data(projectRoot);
tickers = A2.RiskyTickers;
n = numel(tickers);
h = A2.h;
N = numel(A2.Dates);
periodsPerYear = 12;
wB = ones(1, n) / n;
viewLookback = 12;
settings = struct('Tau', 1/h, 'Confidence', 0.50, 'TECeiling', 0.05, 'PeriodsPerYear', periodsPerYear);
decisionRows = (h:N-1)';                 % decide at the end of month t
holdRows = decisionRows + 1;             % hold over month t+1
K = numel(decisionRows);
holdDates = A2.Dates(holdRows);
assert(K == 58, 'Expected 58 out-of-sample months (as in A1).');
gamma = calibrateGamma(A2.R(decisionRows(1)-h+1:decisionRows(1), :), wB);
fprintf('gamma = %.4f, %d rebalances from %s to %s.\n', gamma, K, ...
    string(A2.Dates(decisionRows(1)), 'MMM yyyy'), string(A2.Dates(decisionRows(end)), 'MMM yyyy'));
%[text] ## 2. The rolling loop
%[text] At each decision date $t$ the loop uses only returns up to and including month $t$:
%[text] 1. the Black-Litterman fund repeats Step 1 (`blRebalance`) on the window $t-h+1, \dots, t$;
%[text] 2. the Assignment 1 portfolio is the long-only tangency portfolio of the same window, with the window's mean STEFI return as the risk-free rate (solved exactly by `longOnlyTangency`, so no `fmincon` is needed);
%[text] 3. both sets of weights are held over month $t+1$ and earn that month's returns.
wBL = nan(K, n);
wTan = nan(K, n);
exAnteTE = nan(K, 1);
rawTE = nan(K, 1);
teScale = nan(K, 1);
noShortScale = nan(K, 1);
for k = 1:K
    t = decisionRows(k);
    windowReturns = A2.R(t-h+1:t, :);

    step = blRebalance(windowReturns, A2.R(t-viewLookback+1:t, :), wB, gamma, settings);
    wBL(k, :) = step.Weights;
    exAnteTE(k) = step.TE;
    rawTE(k) = step.RawTE;
    teScale(k) = step.TEScale;
    noShortScale(k) = step.NoShortScale;

    wTan(k, :) = longOnlyTangency(mean(windowReturns, 1), cov(windowReturns), mean(A2.Rf(t-h+1:t)));
end
assert(all(wBL >= -1e-12, 'all') && all(abs(sum(wBL, 2) - 1) < 1e-12), 'BL weights are not long-only and fully invested.');
assert(all(wTan >= 0, 'all') && all(abs(sum(wTan, 2) - 1) < 1e-12), 'Tangency weights are not long-only and fully invested.');
assert(all(exAnteTE <= settings.TECeiling + 1e-12), 'Ex-ante tracking error above the cap.');
fprintf('Ex-ante tracking error of the BL fund: mean %.2f%%, min %.2f%%, max %.2f%% per year.\n', ...
    100*mean(exAnteTE), 100*min(exAnteTE), 100*max(exAnteTE));
%[text] ## 3. Realised returns and turnover
%[text] Every strategy is rebalanced to its target at the start of each month. Between rebalances the weights drift with returns, and turnover is the one-way trade needed to go from the drifted weights back to the new target (Gebbie, Lectures 004 and 005). The equal-weight benchmark also trades a little each month to undo its own drift.
heldReturns = A2.R(holdRows, :);
rf = A2.Rf(holdRows);
rm = A2.Rm(holdRows);
strategyNames = ["Black-Litterman", "Equal-weight benchmark", "A1 rolling tangency", "ALSI"];
weightsByStrategy = {wBL, repmat(wB, K, 1), wTan};
returns = nan(K, numel(strategyNames));
turnover = nan(K, numel(strategyNames));
for s = 1:3
    returns(:, s) = sum(weightsByStrategy{s} .* heldReturns, 2);
    turnover(:, s) = oneWayTurnover(weightsByStrategy{s}, heldReturns);
end
returns(:, 4) = rm;   % the ALSI is a market index, not rebalanced by us
assert(all(isfinite(returns), 'all'), 'Non-finite strategy returns.');
%[text] ## 4. Performance measures
%[text] Following Lecture 005, the annual return is geometric, volatility and the Sharpe ratio use the sample standard deviation, and the Sharpe ratio uses returns in excess of STEFI. Tracking error and the information ratio are measured against the equal-weight benchmark. Jensen's alpha and the CAPM beta come from regressing each strategy's excess return on the ALSI's excess return (`capmRegression`).
S = numel(strategyNames);
wealth = [ones(1, S); cumprod(1 + returns, 1)];
geometricReturn = wealth(end, :).^(periodsPerYear/K) - 1;
volatility = sqrt(periodsPerYear) * std(returns, 0, 1);
excessReturns = returns - rf;
sharpe = sqrt(periodsPerYear) * mean(excessReturns, 1) ./ std(excessReturns, 0, 1);
maxDrawdown = -min(wealth ./ cummax(wealth, 1) - 1, [], 1);
activeReturns = returns - returns(:, 2);
trackingError = sqrt(periodsPerYear) * std(activeReturns, 0, 1);
informationRatio = sqrt(periodsPerYear) * mean(activeReturns, 1) ./ std(activeReturns, 0, 1);
informationRatio(2) = NaN;   % the benchmark against itself
alphaAnnual = nan(1, S); tAlpha = nan(1, S); beta = nan(1, S); tBeta = nan(1, S); r2 = nan(1, S);
for s = 1:S
    capm = capmRegression(excessReturns(:, s), rm - rf, periodsPerYear);
    alphaAnnual(s) = capm.AlphaAnnual; tAlpha(s) = capm.TAlpha;
    beta(s) = capm.Beta; tBeta(s) = capm.TBeta; r2(s) = capm.R2;
end
meanTurnover = mean(turnover, 1, 'omitnan');

performanceTable = table(strategyNames', 100*geometricReturn', 100*volatility', sharpe', 100*maxDrawdown', ...
    100*alphaAnnual', tAlpha', beta', tBeta', r2', 100*trackingError', informationRatio', ...
    100*meanTurnover', 100*periodsPerYear*meanTurnover', wealth(end, :)', ...
    'VariableNames', {'Strategy', 'AnnualReturn_pct', 'Volatility_pct', 'Sharpe', 'MaxDrawdown_pct', ...
    'JensenAlpha_pct_pa', 'tAlpha', 'BetaALSI', 'tBeta', 'R2', 'TEvsEW_pct', 'InformationRatio', ...
    'MeanMonthlyTurnover_pct', 'AnnualTurnover_pct', 'TerminalWealth'})
writetable(performanceTable, fullfile(tableFolder, 'A2_03_performance.csv'));
%[text] The table above holds every number the brief asks for. The weights and monthly returns are saved too, so each figure can be checked against a file.
monthlyTable = array2table([100*returns, 100*rf, 100*turnover(:, 1:3)], 'VariableNames', ...
    {'BL_pct', 'EW_pct', 'Tangency_pct', 'ALSI_pct', 'STEFI_pct', 'BLTurnover_pct', 'EWTurnover_pct', 'TangencyTurnover_pct'});
monthlyTable = addvars(monthlyTable, holdDates, 'Before', 1, 'NewVariableNames', 'HoldingMonth');
writetable(monthlyTable, fullfile(tableFolder, 'A2_03_monthly_returns.csv'));
weightNames = cellstr(tickers);
writetable(addvars(array2table(wBL, 'VariableNames', weightNames), holdDates, 'Before', 1, 'NewVariableNames', 'HoldingMonth'), ...
    fullfile(tableFolder, 'A2_03_weights_BL.csv'));
writetable(addvars(array2table(wTan, 'VariableNames', weightNames), holdDates, 'Before', 1, 'NewVariableNames', 'HoldingMonth'), ...
    fullfile(tableFolder, 'A2_03_weights_tangency.csv'));
%[text] ## 5. Figure: equity curves
%[text] Each curve starts at 1 at the first decision date (end of February 2012). STEFI is included as the cash alternative. The lower panel is the Black-Litterman wealth divided by the benchmark wealth, which rises when the active bets add value.
wealthDates = [A2.Dates(decisionRows(1)); holdDates];
stefiWealth = [1; cumprod(1 + rf)];
fig = figure('Position', [100 100 900 750]);
tl = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile(tl, [1 1]);
plot(ax, wealthDates, wealth, 'LineWidth', 1.6);
hold(ax, 'on')
plot(ax, wealthDates, stefiWealth, '--', 'LineWidth', 1.2, 'Color', [0.4 0.4 0.4]);
hold(ax, 'off')
ylabel(ax, 'Wealth (start = 1)')
title(ax, 'Out-of-sample equity curves, March 2012 to December 2016')
legend(ax, [strategyNames, "STEFI (cash)"], 'Location', 'northwest')
grid(ax, 'on')
ax = nexttile(tl);
plot(ax, wealthDates, wealth(:, 1) ./ wealth(:, 2), 'LineWidth', 1.6);
yline(ax, 1, ':k');
ylabel(ax, 'BL wealth / benchmark wealth')
title(ax, 'Cumulative value added by the active bets')
grid(ax, 'on')
exportgraphics(fig, fullfile(figureFolder, 'A2_03_equity_curves.png'), 'Resolution', 200);
%[text] ## 6. Figure: weights at four rebalance dates
%[text] The bar charts compare the benchmark, the Black-Litterman fund and the Assignment 1 tangency portfolio at the first and last rebalance and two dates in between.
snapshots = round(linspace(1, K, 4));
fig = figure('Position', [100 100 1100 750]);
tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
for j = 1:numel(snapshots)
    k = snapshots(j);
    ax = nexttile(tl);
    bar(ax, categorical(tickers, tickers), 100*[wB; wBL(k, :); wTan(k, :)]');
    ylabel(ax, 'Weight (%)')
    title(ax, sprintf('Held over %s', string(holdDates(k), 'MMM yyyy')))
    grid(ax, 'on')
end
lg = legend(ax, {'Equal-weight benchmark', 'Black-Litterman', 'A1 rolling tangency'}, 'Orientation', 'horizontal');
lg.Layout.Tile = 'north';
exportgraphics(fig, fullfile(figureFolder, 'A2_03_weights_bars.png'), 'Resolution', 200);
%[text] ## 7. Figure: weights over time
%[text] The Black-Litterman fund holds eight of the nine assets every month. The no-short rule always sets exactly one asset, the one the views most want to sell, to zero. Which asset that is changes with the views (most often J520, J510 or ALBI). The tangency portfolio, built from sample means alone, holds three to five assets at a time and switches between them.
fprintf('Assets held: Black-Litterman %.2f on average (min %d, max %d), tangency %.2f (min %d, max %d).\n', ...
    mean(sum(wBL > 1e-10, 2)), min(sum(wBL > 1e-10, 2)), max(sum(wBL > 1e-10, 2)), ...
    mean(sum(wTan > 1e-10, 2)), min(sum(wTan > 1e-10, 2)), max(sum(wTan > 1e-10, 2)));
% Nine distinct colours (MATLAB's default palette has only seven and would repeat two).
assetColours = [0.12 0.47 0.71; 1.00 0.50 0.05; 0.17 0.63 0.17; 0.84 0.15 0.16; 0.58 0.40 0.74; ...
    0.55 0.34 0.29; 0.89 0.47 0.76; 0.50 0.50 0.50; 0.74 0.74 0.13];
assert(size(unique(assetColours, 'rows'), 1) == n, 'Asset colours are not distinct.');
fig = figure('Position', [100 100 1000 750]);
colororder(fig, assetColours);
tl = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile(tl);
area(ax, holdDates, 100*wBL);
ylim(ax, [0 100]); xlim(ax, [holdDates(1) holdDates(end)]); ylabel(ax, 'Weight (%)'); title(ax, 'Black-Litterman fund'); grid(ax, 'on')
ax = nexttile(tl);
area(ax, holdDates, 100*wTan);
ylim(ax, [0 100]); xlim(ax, [holdDates(1) holdDates(end)]); ylabel(ax, 'Weight (%)'); title(ax, 'Assignment 1 rolling tangency portfolio'); grid(ax, 'on')
lg = legend(ax, cellstr(tickers), 'Orientation', 'horizontal');
lg.Layout.Tile = 'south';
exportgraphics(fig, fullfile(figureFolder, 'A2_03_weights_over_time.png'), 'Resolution', 200);
%[text] ## 8. Figure: active risk and turnover through time
fig = figure('Position', [100 100 1000 700]);
tl = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile(tl);
plot(ax, holdDates, 100*exAnteTE, '-o', 'LineWidth', 1.4, 'MarkerSize', 4);
hold(ax, 'on')
yline(ax, 100*settings.TECeiling, '--r', '5% cap');
yline(ax, 3, ':k', '3% (brief''s lower bound)');
hold(ax, 'off')
ylim(ax, [0 6]); ylabel(ax, 'Ex-ante TE (% per year)')
title(ax, 'Black-Litterman ex-ante tracking error after the controls')
grid(ax, 'on')
ax = nexttile(tl);
bar(ax, holdDates, 100*turnover(:, [1 3]), 'grouped');
hold(ax, 'on')
plot(ax, holdDates, 100*turnover(:, 2), 'k-', 'LineWidth', 1.2);
hold(ax, 'off')
ylabel(ax, 'One-way turnover (%)')
title(ax, 'Monthly drift-adjusted turnover')
legend(ax, {'Black-Litterman', 'A1 rolling tangency', 'Equal-weight benchmark'}, 'Location', 'northwest')
grid(ax, 'on')
exportgraphics(fig, fullfile(figureFolder, 'A2_03_risk_and_turnover.png'), 'Resolution', 200);
%[text] ## 9. Checks
%[text] The first rebalance must match the worked example in Step 1, and the benchmark's own active return must be zero.
firstStep = blRebalance(A2.R(decisionRows(1)-h+1:decisionRows(1), :), ...
    A2.R(decisionRows(1)-viewLookback+1:decisionRows(1), :), wB, gamma, settings);
assert(max(abs(firstStep.Weights - wBL(1, :))) < 1e-14, 'First rebalance does not match Step 1.');
assert(all(activeReturns(:, 2) == 0), 'Benchmark active return is not zero.');
assert(abs(wealth(end, 1) - prod(1 + returns(:, 1))) < 1e-12, 'Wealth does not compound the returns.');
fprintf('A2_03_backtest completed.\n');

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":32}
%---
