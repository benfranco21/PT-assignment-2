% RUN_ALL Single entry point for Part II (Black-Litterman backtest) of Assignment 2.
%
%   File:         run_all.m
%   Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
%   Version:      PT_A2_2026_FRNBEN003_v1.0
%   Author:       Benjamin Franco (FRNBEN003)
%   Date:         2026-10-14
%   Purpose:      Set up the path and output folders, log the environment, verify the raw
%                 data file against its SHA-256 checksum, then run the Part II scripts in order.
%   Inputs:       data/raw/PT-DATA-ALBI-JIBAR-JSEIND-Daily-1994-2017.xlsx,
%                 data/raw/DATA-CHECKSUM.txt
%   Outputs:      outputs/logs/run_log_<timestamp>.txt (diary of this run);
%                 outputs/figures/, outputs/tables/, data/derived/ (filled by the Part II scripts).
%   Dependencies: Base MATLAB only (no toolboxes). Uses startup.m.
%
%   Usage: run_all   (the current folder does not matter)

rng(20261014, 'twister');                       % reproducible randomness

% --- Project root, from this file's own location -------------------------
projectRoot = fileparts(mfilename('fullpath'));
run(fullfile(projectRoot, 'startup.m'));

% --- Output folders --------------------------------------------------------
outDirs = {fullfile('outputs', 'figures'), fullfile('outputs', 'tables'), ...
           fullfile('outputs', 'logs'), fullfile('data', 'derived')};
for i = 1:numel(outDirs)
    d = fullfile(projectRoot, outDirs{i});
    if ~isfolder(d), mkdir(d); end
end

% --- Log everything printed from here on -------------------------------
runStamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
logFile  = fullfile(projectRoot, 'outputs', 'logs', ['run_log_' runStamp '.txt']);
diary(logFile);
cleanupObj = onCleanup(@() diary('off'));       % close the log even if an error occurs

fprintf('Project : PT_A2_2026_FRNBEN003_v1.0\n');
fprintf('Run time: %s\n', char(datetime('now')));
fprintf('MATLAB  : %s\n', version);
fprintf('Root    : %s\n', projectRoot);
fprintf('RNG     : twister, seed 20261014\n');
fprintf('Installed toolboxes:\n');
ver;

% --- Raw data integrity check -------------------------------------------
rawDir   = fullfile(projectRoot, 'data', 'raw');
rawName  = 'PT-DATA-ALBI-JIBAR-JSEIND-Daily-1994-2017.xlsx';
rawFile  = fullfile(rawDir, rawName);
sumFile  = fullfile(rawDir, 'DATA-CHECKSUM.txt');
if ~isfile(rawFile)
    error('run_all:missingData', 'Raw data file not found: %s', rawFile);
end
if ~isfile(sumFile)
    error('run_all:missingChecksum', 'Checksum file not found: %s', sumFile);
end
txt      = fileread(sumFile);
tok      = regexp(txt, '([0-9a-fA-F]{64})', 'tokens', 'once');
if isempty(tok)
    error('run_all:badChecksum', 'No SHA-256 value found in %s', sumFile);
end
expected = lower(tok{1});
md       = java.security.MessageDigest.getInstance('SHA-256');
fid      = fopen(rawFile, 'r');
bytes    = fread(fid, Inf, '*uint8');
fclose(fid);
md.update(bytes);
actual   = lower(reshape(dec2hex(typecast(md.digest(), 'uint8'), 2).', 1, []));
if ~strcmp(actual, expected)
    error('run_all:checksumMismatch', ...
        ['SHA-256 of %s does not match DATA-CHECKSUM.txt.\n  expected: %s\n  actual:   %s\n' ...
         'The data file has been changed or corrupted; restore the original file.'], ...
        rawName, expected, actual);
end
fprintf('Raw data checksum OK (SHA-256 %s)\n', actual);

% === PART II SCRIPTS ======================================================
% Scripts run in order. The full backtest scripts will be added after this one.
run(fullfile(projectRoot, 'scripts', 'A2_01_one_rebalance.m'));
% === END PART II SCRIPTS ==================================================

fprintf('run_all completed\n');
