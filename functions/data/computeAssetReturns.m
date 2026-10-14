function returns = computeAssetReturns(prices)
%COMPUTEASSETRETURNS Compute aligned simple and log returns from prices.
%
%   RETURNS = COMPUTEASSETRETURNS(PRICES) accepts a timetable of strictly
%   positive price or total-return indices. The return at row t is measured
%   from PRICES.Time(t-1) to PRICES.Time(t) and is timestamped at t.
%
% SPDX-License-Identifier: BSD-3-Clause

arguments
    prices timetable
end

if height(prices) < 2
    error('STA4028Z:InsufficientPrices', ...
        'At least two price observations are required.');
end
priceValues = prices{:,:};
if any(~isfinite(priceValues), 'all') || any(priceValues <= 0, 'all')
    error('STA4028Z:InvalidPrices', ...
        'Prices must be positive and finite before returns are computed.');
end

simpleValues = priceValues(2:end,:) ./ priceValues(1:end-1,:) - 1;
logValues = diff(log(priceValues), 1, 1);
returnTime = prices.Time(2:end);
variableNames = prices.Properties.VariableNames;

returns = struct();
returns.Simple = array2timetable(simpleValues, 'RowTimes', returnTime, ...
    'VariableNames', variableNames);
returns.Log = array2timetable(logValues, 'RowTimes', returnTime, ...
    'VariableNames', variableNames);
end
