%[text] # STA4028Z Portfolio Theory, Assignment 2
%[text] ## Part II, Step 2: choosing the risk aversion $\gamma$
%[text] **File:** `A2_02_choose_gamma.m`
%[text] **Version:** `PT_A2_2026_FRNBEN003_v1.0`
%[text] **Author:** Benjamin Franco (FRNBEN003)
%[text] **Date:** 2026-10-14
%[text] **Purpose:** Motivate the value of $\gamma$ used in the backtest. I calibrate $\gamma$ from the benchmark in the first estimation window, then check over a grid of $\gamma$ values how the raw tracking error and the two controls (tracking-error ceiling, no short selling) behave at every decision date. No realised portfolio return is used, so the choice cannot be tuned to the backtest result.
%[text] **Inputs:** data/raw/PT-DATA-ALBI-JIBAR-JSEIND-Daily-1994-2017.xlsx (through loadA2Data).
%[text] **Outputs:** printed tables, `outputs/tables/A2_02_gamma_grid.csv`, `outputs/figures/A2_02_gamma_choice.png`
%[text] **Dependencies:** base MATLAB only. functions/data/loadA2Data.m, functions/portfolio/calibrateGamma.m, functions/portfolio/blRebalance.m (and the functions it calls).
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
%[text] ## 1. Data and fixed settings (the same as Step 1)
A2 = loadA2Data(projectRoot);
tickers = A2.RiskyTickers;
n = numel(tickers);
h = A2.h;
N = numel(A2.Dates);
wB = ones(1, n) / n;
viewLookback = 12;
settings = struct('Tau', 1/h, 'Confidence', 0.50, 'TECeiling', 0.05, 'PeriodsPerYear', 12);
decisionRows = h:N-1;                 % decide at t, hold over t+1
numberOfDecisions = numel(decisionRows);
fprintf('%d decision dates: %s to %s.\n', numberOfDecisions, ...
    string(A2.Dates(decisionRows(1)), 'MMM yyyy'), string(A2.Dates(decisionRows(end)), 'MMM yyyy'));
assert(numberOfDecisions == 58, 'Expected 58 decision dates (as in A1).');
%[text] ## 2. Calibrate $\gamma$ from the benchmark
%[text] The equilibrium returns are $\Pi = \gamma\Sigma\omega_B$, so the benchmark's own equilibrium return is $\omega_B'\Pi = \gamma\,\omega_B'\Sigma\omega_B$. I set this equal to the benchmark's average monthly return over the first estimation window, which gives
%[text] $\gamma = \dfrac{\text{mean benchmark return}}{\text{benchmark variance}}$.
%[text] This is the calibration Black and Litterman (1992) use for the market portfolio. It keeps $\Pi$ on the same scale as the views $V$, which are also average returns. If $\gamma$ is too small, $\Pi$ sits far below every view. If it is too large, $\Pi$ sits far above. In both cases the posterior is pulled hard towards the views and the raw bets are large. I fix $\gamma$ at the value from the first window and keep it for the whole backtest, so it uses no data after the first decision date.
firstWindow = A2.R(decisionRows(1)-h+1:decisionRows(1), :);
[gammaChosen, calib] = calibrateGamma(firstWindow, wB);
fprintf('First window: benchmark mean %.3f%% per month, variance %.3g, implied gamma = %.2f\n', ...
    100*calib.BenchmarkMean, calib.BenchmarkVariance, gammaChosen);
%[text] The same calibration at every later decision date shows how stable the value is. It is only a diagnostic and is not used to change $\gamma$ during the backtest.
impliedGamma = nan(numberOfDecisions, 1);
for k = 1:numberOfDecisions
    t = decisionRows(k);
    impliedGamma(k) = calibrateGamma(A2.R(t-h+1:t, :), wB);
end
fprintf('Implied gamma over all decision dates: median %.2f, min %.2f, max %.2f\n', ...
    median(impliedGamma), min(impliedGamma), max(impliedGamma));
%[text] ## 3. Check the choice over a grid of $\gamma$
%[text] For each $\gamma$ on the grid I run the rebalance at all 58 decision dates and record the raw tracking error of equation (16), how often each control binds, and the final tracking error after the controls. The brief asks for a tracking error between 3% and 10% a year with no short selling. I cap the tracking error at 5% a year, which suits a fund that stays close to its benchmark. Section 4 shows that the cap almost never changes the final portfolio, because the no-short rule already shrinks the bets further.
gammaGrid = unique([1 2 3 4 5 6 8 10 12 15 20 25 30 40 50 75 100, gammaChosen]);
G = numel(gammaGrid);
rawTE = nan(G, numberOfDecisions);
finalTE = nan(G, numberOfDecisions);
teBinding = false(G, numberOfDecisions);
noShortBinding = false(G, numberOfDecisions);
for g = 1:G
    for k = 1:numberOfDecisions
        t = decisionRows(k);
        step = blRebalance(A2.R(t-h+1:t, :), A2.R(t-viewLookback+1:t, :), wB, gammaGrid(g), settings);
        rawTE(g, k) = step.RawTE;
        finalTE(g, k) = step.TE;
        teBinding(g, k) = step.TEBinding;
        noShortBinding(g, k) = step.NoShortBinding;
    end
end
inBand = finalTE >= 0.03 & finalTE <= 0.10;
gridTable = table(gammaGrid', 100*median(rawTE, 2), 100*min(rawTE, [], 2), 100*max(rawTE, [], 2), ...
    100*mean(teBinding, 2), 100*mean(noShortBinding, 2), 100*mean(finalTE, 2), 100*mean(inBand, 2), ...
    'VariableNames', {'Gamma', 'MedianRawTE_pct', 'MinRawTE_pct', 'MaxRawTE_pct', ...
    'TECeilingBinds_pctMonths', 'NoShortBinds_pctMonths', 'MeanFinalTE_pct', 'FinalTEIn3to10_pctMonths'})
writetable(gridTable, fullfile(tableFolder, 'A2_02_gamma_grid.csv'));
%[text] ## 4. What the grid shows
%[text] Two things stand out.
%[text] First, the raw tracking error does not keep falling as $\gamma$ grows. The active bets are $\frac{1}{\gamma}f(\mathbb{E}[R]^* - \Pi)$, and $\Pi$ itself grows with $\gamma$, so for large $\gamma$ the equilibrium moves far above the views and the gap $V - \Pi$ grows again. The raw tracking error is smallest for $\gamma$ in the twenties, and very small values of $\gamma$ give raw tracking errors far above 100% a year.
%[text] Second, the no-short rule binds at 57 or 58 of the 58 dates for every $\gamma$ up to 15, and still at most dates for larger $\gamma$. The equal-weight benchmark holds only $1/9 \approx 11.1\%$ in each asset, so any active bet below $-11.1\%$ would create a short position, and the controls must shrink the bets until it does not. The final tracking error is therefore set mostly by the no-short rule, and stays near 2% to 5% a year whatever $\gamma$ is. The brief's 3% to 10% band is reached in part of the months only. A larger tracking error would need a benchmark with bigger weights in the assets the views want to sell, or a long-only optimiser instead of scaling.
%[text] Both controls multiply the same active vector, so the final bets are shrunk by the smaller of the two factors. At the chosen $\gamma$ the no-short rule alone keeps the final tracking error below 5% in every month, so a 5% cap gives exactly the same portfolios as a 10% cap. The 5% cap is a hard limit that would only act in a month where the views are mild enough for the no-short rule to shrink the bets less.
%[text] The calibrated $\gamma$ is printed in the grid row below. It is not chosen to maximise anything on the grid. The grid only confirms that it gives a sensible raw tracking error and keeps the final tracking error inside or close to the band.
chosenRow = gridTable(abs(gridTable.Gamma - gammaChosen) < 1e-12, :)
assert(height(chosenRow) == 1, 'The calibrated gamma is missing from the grid.');
%[text] ## 5. Figure: the evidence for the choice of $\gamma$
fig = figure('Position', [100 100 900 1000]);
tl = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile(tl);
patch(ax1, [gammaGrid(1) gammaGrid(end) gammaGrid(end) gammaGrid(1)], [3 3 10 10], ...
    [0.85 0.92 0.85], 'EdgeColor', 'none', 'DisplayName', 'Brief''s 3% to 10% band');
hold(ax1, 'on')
plot(ax1, gammaGrid, 100*median(rawTE, 2), '-o', 'LineWidth', 1.5, 'DisplayName', 'Raw TE, median over dates');
plot(ax1, gammaGrid, 100*max(rawTE, [], 2), ':', 'LineWidth', 1.2, 'DisplayName', 'Raw TE, max over dates');
plot(ax1, gammaGrid, 100*mean(finalTE, 2), '-s', 'LineWidth', 1.5, 'DisplayName', 'Final TE after controls, mean');
xline(ax1, gammaChosen, '--k', sprintf('\\gamma = %.2f', gammaChosen), 'HandleVisibility', 'off');
hold(ax1, 'off')
set(ax1, 'XScale', 'log', 'YScale', 'log')
ylabel(ax1, 'Tracking error (% per year)')
title(ax1, 'Ex-ante tracking error against \gamma (58 decision dates)')
legend(ax1, 'Location', 'northeast')
grid(ax1, 'on')

ax2 = nexttile(tl);
plot(ax2, gammaGrid, 100*mean(teBinding, 2), '-o', 'LineWidth', 1.5, 'DisplayName', 'TE ceiling binds');
hold(ax2, 'on')
plot(ax2, gammaGrid, 100*mean(noShortBinding, 2), '-s', 'LineWidth', 1.5, 'DisplayName', 'No-short rule binds');
plot(ax2, gammaGrid, 100*mean(inBand, 2), '-^', 'LineWidth', 1.5, 'DisplayName', 'Final TE inside 3% to 10%');
xline(ax2, gammaChosen, '--k', 'HandleVisibility', 'off');
hold(ax2, 'off')
set(ax2, 'XScale', 'log')
ylim(ax2, [0 105])
ylabel(ax2, '% of decision dates')
xlabel(ax2, 'Risk aversion \gamma (log scale)')
title(ax2, 'How often each control is active')
legend(ax2, 'Location', 'best')
grid(ax2, 'on')

ax3 = nexttile(tl);
plot(ax3, A2.Dates(decisionRows), impliedGamma, '-', 'LineWidth', 1.5, 'DisplayName', 'Implied \gamma at each date');
hold(ax3, 'on')
yline(ax3, gammaChosen, '--k', 'Used in backtest (first window)', 'LabelHorizontalAlignment', 'left');
hold(ax3, 'off')
ylabel(ax3, '\gamma')
title(ax3, 'Benchmark-implied risk aversion, re-estimated at every decision date (diagnostic only)')
grid(ax3, 'on')

exportgraphics(fig, fullfile(figureFolder, 'A2_02_gamma_choice.png'), 'Resolution', 200);
%[text] ## 6. Result passed to the backtest
%[text] The backtest calls `calibrateGamma` on the first window itself, so it uses exactly this value without reading a file written by this script.
fprintf('Chosen gamma = %.4f (calibrated on %s to %s).\n', gammaChosen, ...
    string(A2.Dates(decisionRows(1)-h+1), 'MMM yyyy'), string(A2.Dates(decisionRows(1)), 'MMM yyyy'));
fprintf('A2_02_choose_gamma completed.\n');

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":32}
%---
