function prepared = prepareCourseData(fileName, options)
%PREPARECOURSEDATA Build the reproducible monthly STA4028Z dataset.
%
%   PREPARED = PREPARECOURSEDATA(FILENAME) imports the raw workbook,
%   samples the last available observation in each month, removes the
%   discontinued J500 series, selects a common stable sample, carries
%   forward isolated missing monthly prices, and computes returns.
%
%   The long ALBI gap after its isolated August 2003 observation is treated
%   as a structural break in availability. The common sample therefore
%   starts only after the final missing run longer than MaxInternalGap.
%
% SPDX-License-Identifier: BSD-3-Clause

arguments
    fileName (1,1) string
    options.ExcludedAssets (1,:) string = "J500"
    options.MaxInternalGap (1,1) double {mustBeInteger,mustBeNonnegative} = 1
end

raw = readRawMarketWorkbook(fileName);
dailyPrices = raw.DailyPrices;

available = string(dailyPrices.Properties.VariableNames);
unknownExclusions = setdiff(options.ExcludedAssets, available);
if ~isempty(unknownExclusions)
    error('STA4028Z:UnknownAsset', ...
        'Excluded asset is not present: %s', join(unknownExclusions, ', '));
end
kept = setdiff(available, options.ExcludedAssets, 'stable');
dailyPrices = dailyPrices(:, cellstr(kept));

% Sample the last finite observation of each series in each month. This is
% implemented explicitly because synchronising daily markets produces NaNs
% on dates where one market is closed while another is open. Selecting the
% last timetable row would therefore not always select the last observation.
monthlyUnfilled = monthlyLastObserved(dailyPrices);

values = monthlyUnfilled{:,:};
numberOfAssets = width(monthlyUnfilled);
firstObserved = nan(numberOfAssets,1);
lastObserved = nan(numberOfAssets,1);
firstUsable = nan(numberOfAssets,1);
largestGap = zeros(numberOfAssets,1);

for assetIndex = 1:numberOfAssets
    observed = find(isfinite(values(:,assetIndex)));
    if isempty(observed)
        error('STA4028Z:EmptyAsset', ...
            'Asset %s has no observations.', kept(assetIndex));
    end
    firstObserved(assetIndex) = observed(1);
    lastObserved(assetIndex) = observed(end);
    firstUsable(assetIndex) = observed(1);

    runs = missingRuns(~isfinite(values(:,assetIndex)));
    internal = runs(runs(:,1) > observed(1) & runs(:,2) < observed(end), :);
    if ~isempty(internal)
        largestGap(assetIndex) = max(internal(:,3));
        longRuns = internal(internal(:,3) > options.MaxInternalGap, :);
        if ~isempty(longRuns)
            % Start after the final structural gap. Later long gaps would be
            % detected again once the common sample is selected.
            firstUsable(assetIndex) = max(longRuns(:,2)) + 1;
        end
    end
end

commonStart = max(firstUsable);
commonEnd = min(lastObserved);
if commonStart >= commonEnd
    error('STA4028Z:NoCommonSample', ...
        'No common stable monthly sample exists for the selected assets.');
end

monthlyBounded = monthlyUnfilled(commonStart:commonEnd,:);
boundedValues = monthlyBounded{:,:};
missingBeforeFill = sum(~isfinite(boundedValues),1).';
maximumGapInSample = zeros(numberOfAssets,1);

for assetIndex = 1:numberOfAssets
    runs = missingRuns(~isfinite(boundedValues(:,assetIndex)));
    if ~isempty(runs)
        maximumGapInSample(assetIndex) = max(runs(:,3));
    end
    if maximumGapInSample(assetIndex) > options.MaxInternalGap
        error('STA4028Z:LongInternalGap', ...
            ['Asset %s has a missing monthly run of length %d inside ' ...
             'the proposed common sample.'], kept(assetIndex), ...
             maximumGapInSample(assetIndex));
    end
end

% A previous monthly total-return index implies a zero return for an
% isolated month without a recorded new index observation. This is applied
% only after the structural sample boundaries and gap checks above.
monthlyPrices = fillmissing(monthlyBounded, 'previous');
if any(~isfinite(monthlyPrices{:,:}), 'all')
    error('STA4028Z:UnresolvedMissingData', ...
        'Missing prices remain after the declared isolated-gap treatment.');
end

asset = kept(:);
firstObservedDate = monthlyUnfilled.Time(firstObserved);
firstUsableDate = monthlyUnfilled.Time(firstUsable);
lastObservedDate = monthlyUnfilled.Time(lastObserved);
missingReport = table(asset, firstObservedDate, firstUsableDate, ...
    lastObservedDate, largestGap, missingBeforeFill, maximumGapInSample, ...
    'VariableNames', {'Asset','FirstObserved','FirstUsable', ...
    'LastObserved','LargestGapBeforeBounding','FilledObservations', ...
    'MaximumGapInCommonSample'});

prepared = struct();
prepared.SourceFile = raw.SourceFile;
prepared.SourceSHA256 = raw.SourceSHA256;
prepared.Dictionary = raw.Dictionary;
prepared.ExcludedAssets = options.ExcludedAssets;
prepared.DailyPrices = dailyPrices;
prepared.MonthlyPricesBeforeFill = monthlyBounded;
prepared.MonthlyPrices = monthlyPrices;
prepared.Returns = computeAssetReturns(monthlyPrices);
prepared.MissingReport = missingReport;
prepared.CommonSampleStart = monthlyPrices.Time(1);
prepared.CommonSampleEnd = monthlyPrices.Time(end);
prepared.MaxInternalGap = options.MaxInternalGap;
end

function runs = missingRuns(isMissing)
%MISSINGRUNS Return [start,end,length] for every true run.

isMissing = logical(isMissing(:));
changes = diff([false; isMissing; false]);
starts = find(changes == 1);
ends = find(changes == -1) - 1;
runs = [starts, ends, ends-starts+1];
end

function monthly = monthlyLastObserved(daily)
%MONTHLYLASTOBSERVED Select each series' last finite value in each month.

monthStart = dateshift(daily.Time, 'start', 'month');
months = unique(monthStart);
dailyValues = daily{:,:};
monthlyValues = nan(numel(months), width(daily));

for monthIndex = 1:numel(months)
    rowMask = monthStart == months(monthIndex);
    monthValues = dailyValues(rowMask,:);
    for assetIndex = 1:width(daily)
        lastObserved = find(isfinite(monthValues(:,assetIndex)), 1, 'last');
        if ~isempty(lastObserved)
            monthlyValues(monthIndex,assetIndex) = ...
                monthValues(lastObserved,assetIndex);
        end
    end
end

monthEnd = dateshift(months, 'end', 'month');
monthly = array2timetable(monthlyValues, 'RowTimes', monthEnd, ...
    'VariableNames', daily.Properties.VariableNames);
end
