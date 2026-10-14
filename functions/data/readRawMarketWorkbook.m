function raw = readRawMarketWorkbook(fileName)
%READRAWMARKETWORKBOOK Read the controlled STA4028Z source workbook.
%
%   RAW = READRAWMARKETWORKBOOK(FILENAME) imports the total-return and
%   money-market series used by the course. The sheet and column selections
%   are deliberately explicit because the source workbook has different
%   header and date layouts on different sheets.
%
%   This function uses base MATLAB only. It does not require Financial
%   Toolbox import or portfolio objects.
%
% SPDX-License-Identifier: BSD-3-Clause

arguments
    fileName (1,1) string
end

if ~isfile(fileName)
    error('STA4028Z:MissingRawWorkbook', ...
        'Raw workbook does not exist: %s', fileName);
end

expectedSheets = ["ALBI TRI"; "JIBAR"; "JSE ICB 0500 Indices"; ...
    "JSE Various Indices"];
actualSheets = string(sheetnames(fileName));
if ~isequal(actualSheets, expectedSheets)
    error('STA4028Z:UnexpectedWorkbookSchema', ...
        'The source workbook sheet names or order have changed.');
end

% Sheet-specific source selections. Column numbers refer to the original
% workbook, not to a table produced by an import heuristic.
series = cell(12,1);
series{1} = extractExcelSeries(fileName, "JIBAR", 3, 5, "STEFI");
series{2} = extractExcelSeries(fileName, "ALBI TRI", 3, 4, "ALBI");
series{3} = extractExcelSeries(fileName, ...
    "JSE Various Indices", 3, 19, "ALSI");

sectorNames = ["J500", "J510", "J520", "J530", "J540", ...
    "J550", "J560", "J580", "J590"];
sectorColumns = 4:3:28;
for sectorIndex = 1:numel(sectorNames)
    series{sectorIndex+3} = extractExcelSeries(fileName, ...
        "JSE ICB 0500 Indices", 1, sectorColumns(sectorIndex), ...
        sectorNames(sectorIndex));
end

% Synchronise to the union of observed daily dates. Missing values remain
% missing here; no data treatment belongs in the raw import function.
dailyPrices = series{1};
for seriesIndex = 2:numel(series)
    dailyPrices = synchronize(dailyPrices, series{seriesIndex}, ...
        'union', 'fillwithmissing');
end
dailyPrices = sortrows(dailyPrices);

variable = ["STEFI"; "ALBI"; "ALSI"; sectorNames(:)];
assetClass = ["Cash"; "Bond"; "Equity market"; ...
    repmat("Equity sector", numel(sectorNames), 1)];
sourceSheet = ["JIBAR"; "ALBI TRI"; "JSE Various Indices"; ...
    repmat("JSE ICB 0500 Indices", numel(sectorNames), 1)];
sourceField = ["RATESTEFI Close"; "ALBI TRI"; "J203 TRI"; ...
    sectorNames(:) + " TRI"];
includedByDefault = variable ~= "J500";
dictionary = table(variable, assetClass, sourceSheet, sourceField, ...
    includedByDefault, 'VariableNames', {'Variable','AssetClass', ...
    'SourceSheet','SourceField','IncludedByDefault'});

raw = struct();
raw.SourceFile = fileName;
raw.SourceSHA256 = sha256File(fileName);
raw.DailyPrices = dailyPrices;
raw.Dictionary = dictionary;
end

function series = extractExcelSeries(fileName, sheetName, dateColumn, ...
    valueColumn, variableName)
%EXTRACTEXCELSERIES Convert one explicitly selected worksheet field.

cells = readcell(fileName, 'Sheet', sheetName);
if size(cells,1) < 5 || size(cells,2) < max(dateColumn,valueColumn)
    error('STA4028Z:UnexpectedWorkbookSchema', ...
        'Sheet %s does not contain the expected data range.', sheetName);
end

numberOfRows = size(cells,1) - 4;
time = NaT(numberOfRows,1);
value = nan(numberOfRows,1);

for rowIndex = 1:numberOfRows
    rawDate = cells{rowIndex+4,dateColumn};
    rawValue = cells{rowIndex+4,valueColumn};

    if isdatetime(rawDate) && isscalar(rawDate)
        time(rowIndex) = rawDate;
    elseif isnumeric(rawDate) && isscalar(rawDate) && isfinite(rawDate)
        time(rowIndex) = datetime(rawDate, 'ConvertFrom', 'excel');
    elseif (ischar(rawDate) || (isstring(rawDate) && isscalar(rawDate)))
        try
            time(rowIndex) = datetime(rawDate);
        catch
            % Non-date spreadsheet text is left as NaT and removed below.
        end
    end

    if isnumeric(rawValue) && isscalar(rawValue) && isfinite(rawValue)
        value(rowIndex) = double(rawValue);
    elseif ischar(rawValue) || (isstring(rawValue) && isscalar(rawValue))
        candidate = str2double(string(rawValue));
        if isfinite(candidate)
            value(rowIndex) = candidate;
        end
    end
end

valid = ~isnat(time) & isfinite(value);
time = time(valid);
value = value(valid);
[time, order] = sort(time);
value = value(order);

% Retain the last occurrence if a source sheet contains a duplicate date.
[time, uniqueIndex] = unique(time, 'last');
value = value(uniqueIndex);

series = timetable(time, value, ...
    'VariableNames', {char(variableName)});
% MATLAB releases differ in whether the timetable row dimension inherits
% the local input name `time` or uses the conventional name `Time`.
% Normalise it here because the teaching scripts deliberately use tt.Time.
series.Properties.DimensionNames{1} = 'Time';
end
