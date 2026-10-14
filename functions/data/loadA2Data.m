function A2 = loadA2Data(projectRoot)
%LOADA2DATA Load the monthly Assignment 2 dataset (same sample as Assignment 1).
%
%   File:         loadA2Data.m
%   Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
%   Version:      PT_A2_2026_FRNBEN003_v1.0
%   Author:       Benjamin Franco (FRNBEN003)
%   Date:         2026-10-14
%   Purpose:      Read the raw daily workbook, build month-end total-return
%                 indices with Tim Gebbie's prepareCourseData (base MATLAB),
%                 and return the Assignment 1 asset universe as simple
%                 monthly returns, with checks that the sample matches A1.
%   Inputs:       projectRoot - absolute path of the project folder.
%   Outputs:      A2 - struct with fields
%                   .RiskyTickers   1x9 string  (ALBI, J510 ... J590)
%                   .Dates          145x1 datetime (month-end of each return)
%                   .R              145x9 simple returns of the risky assets
%                   .Rf             145x1 simple returns of STEFI (risk-free)
%                   .Rm             145x1 simple returns of ALSI (CAPM market)
%                   .Prices         146x9 month-end total-return indices
%                   .h              rolling window length (87 = A1 window)
%                   .SourceSHA256   SHA-256 of the raw workbook
%   Dependencies: prepareCourseData.m, readRawMarketWorkbook.m,
%                 computeAssetReturns.m, sha256File.m (Tim Gebbie,
%                 BSD-3-Clause, copied unchanged into functions/data).

rawFile = fullfile(projectRoot, 'data', 'raw', ...
    'PT-DATA-ALBI-JIBAR-JSEIND-Daily-1994-2017.xlsx');
if ~isfile(rawFile)
    error('A2:MissingData', 'Raw data file not found: %s', rawFile);
end

prepared = prepareCourseData(string(rawFile));
prices = prepared.MonthlyPrices;
simple = prepared.Returns.Simple;

riskyTickers = ["ALBI","J510","J520","J530","J540","J550","J560","J580","J590"];

A2 = struct();
A2.RiskyTickers = riskyTickers;
A2.Dates = simple.Time;
A2.R = simple{:, cellstr(riskyTickers)};
A2.Rf = simple{:, 'STEFI'};
A2.Rm = simple{:, 'ALSI'};
A2.Prices = prices{:, cellstr(riskyTickers)};
A2.PriceDates = prices.Time;
A2.SourceSHA256 = prepared.SourceSHA256;

% Same window rule as Assignment 1: the first 60% of the sample.
A2.h = floor(0.6 * height(simple));

% ---- Diagnostics: the sample must match Assignment 1 exactly ----
assert(height(simple) == 145, 'A2:SampleLength', ...
    'Expected 145 monthly returns (as in A1), found %d.', height(simple));
assert(A2.h == 87, 'A2:WindowLength', ...
    'Expected a rolling window of 87 months (as in A1), found %d.', A2.h);
assert(year(prices.Time(1)) == 2004 && month(prices.Time(1)) == 11, ...
    'A2:SampleStart', 'Expected the first price in November 2004.');
assert(year(prices.Time(end)) == 2016 && month(prices.Time(end)) == 12, ...
    'A2:SampleEnd', 'Expected the last price in December 2016.');
assert(all(isfinite([A2.R, A2.Rf, A2.Rm]), 'all'), 'A2:NonFinite', ...
    'Returns contain non-finite values.');
maxGap = max(abs(A2.Prices(2:end,:) ./ A2.Prices(1:end-1,:) - 1 - A2.R), [], 'all');
assert(maxGap < 1e-12, 'A2:ReturnAlignment', ...
    'Returns do not match the month-end prices (max gap %.3g).', maxGap);

fprintf('Data: %s to %s, %d monthly returns, %d risky assets, window h = %d, out-of-sample months = %d\n', ...
    string(A2.Dates(1), 'MMM yyyy'), string(A2.Dates(end), 'MMM yyyy'), ...
    numel(A2.Dates), numel(riskyTickers), A2.h, numel(A2.Dates) - A2.h);
end
