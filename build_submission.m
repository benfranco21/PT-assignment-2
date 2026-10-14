% BUILD_SUBMISSION Build the standalone code zip for submission.
%
%   File:         build_submission.m
%   Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
%   Version:      PT_A2_2026_FRNBEN003_v1.0
%   Author:       Benjamin Franco (FRNBEN003)
%   Date:         2026-10-14
%   Purpose:      Copy an explicit list of project files into a staging folder and zip it as
%                 submission/PT_A2_2026_FRNBEN003_v1.0.zip, which holds one top-level folder
%                 PT_A2_2026_FRNBEN003_v1.0/. The report, git data, virtual environment, run
%                 outputs, DEVELOPMENT.md and TEMPLATE_*.m helpers are never copied.
%   Inputs:       README.md, LICENSE-NOTICE.md, startup.m, run_all.m, data/raw/, functions/,
%                 scripts/, verification/ (verify_*.py, run_all_checks.py, requirements.txt).
%   Outputs:      submission/PT_A2_2026_FRNBEN003_v1.0.zip; the file list and size are printed.
%   Dependencies: Base MATLAB only (copyfile, zip, unzip).
%
%   Usage: build_submission   (the current folder does not matter)

projectRoot = fileparts(mfilename('fullpath'));
version_id  = 'PT_A2_2026_FRNBEN003_v1.0';
rawName     = 'PT-DATA-ALBI-JIBAR-JSEIND-Daily-1994-2017.xlsx';

stageBase = tempname;
checkDir  = tempname;
cleanupObj = onCleanup(@() cellfun(@(d) rmdirIfExists(d), {stageBase, checkDir}));
stage = fullfile(stageBase, version_id);
mkdir(stage);

% --- Copy the allowlist -------------------------------------------------
fileList = {'README.md', 'LICENSE-NOTICE.md', 'startup.m', 'run_all.m', ...
            fullfile('data', 'raw', rawName), fullfile('data', 'raw', 'DATA-CHECKSUM.txt'), ...
            fullfile('verification', 'run_all_checks.py'), ...
            fullfile('verification', 'requirements.txt')};
vfiles = dir(fullfile(projectRoot, 'verification', 'verify_*.py'));
fileList = [fileList, cellfun(@(f) fullfile('verification', f), {vfiles.name}, 'UniformOutput', false)];
if numel(vfiles) ~= 6
    error('build_submission:verify', 'Expected 6 verify_*.py files, found %d.', numel(vfiles));
end
for i = 1:numel(fileList)
    copyOne(projectRoot, stage, fileList{i});
end
for d = {'functions', 'scripts'}
    src = fullfile(projectRoot, d{1});
    if ~isfolder(src), error('build_submission:missing', 'Missing folder: %s', src); end
    [ok, msg] = copyfile(src, fullfile(stage, d{1}));
    if ~ok, error('build_submission:copy', 'Copy of %s failed: %s', d{1}, msg); end
end
% Empty output folders (zip drops empty folders, so each gets a .gitkeep)
for d = {'figures', 'tables', 'logs'}
    mkdir(fullfile(stage, 'outputs', d{1}));
    fclose(fopen(fullfile(stage, 'outputs', d{1}, '.gitkeep'), 'w'));
end

% --- Remove anything that must not ship (dev helpers, editor junk) ------
junk = [dir(fullfile(stage, '**', 'TEMPLATE_*.m')); dir(fullfile(stage, '**', '*.asv')); ...
        dir(fullfile(stage, '**', '*.m~')); dir(fullfile(stage, '**', '.DS_Store'))];
for i = 1:numel(junk)
    delete(fullfile(junk(i).folder, junk(i).name));
end

% --- Raw data integrity (staged copy vs checksum file) -------------------
tok = regexp(fileread(fullfile(stage, 'data', 'raw', 'DATA-CHECKSUM.txt')), ...
             '([0-9a-fA-F]{64})', 'tokens', 'once');
fid = fopen(fullfile(stage, 'data', 'raw', rawName), 'r');
bytes = fread(fid, Inf, '*uint8'); fclose(fid);
md = java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
actual = lower(reshape(dec2hex(typecast(md.digest(), 'uint8'), 2).', 1, []));
if isempty(tok) || ~strcmp(actual, lower(tok{1}))
    error('build_submission:checksum', 'Raw data does not match DATA-CHECKSUM.txt; not building.');
end

% --- Zip ----------------------------------------------------------------
outDir = fullfile(projectRoot, 'submission');
if ~isfolder(outDir), mkdir(outDir); end
zipFile = fullfile(outDir, [version_id '.zip']);
if isfile(zipFile), delete(zipFile); end
zip(zipFile, version_id, stageBase);

% --- Re-open the zip and check what is really inside -------------------
unzip(zipFile, checkDir);
entries = dir(fullfile(checkDir, '**', '*'));
entries = entries(~[entries.isdir]);
rel = cellfun(@(f, n) strrep(extractAfter([f filesep n], [checkDir filesep]), filesep, '/'), ...
              {entries.folder}, {entries.name}, 'UniformOutput', false);
rel = sort(rel);
forbidden = {'.git', '.venv', '__pycache__', 'report', 'submission', 'DEVELOPMENT.md', ...
             '*.asv', 'run_log_*', 'TEMPLATE_*', '.DS_Store', '__MACOSX'};
for i = 1:numel(rel)
    parts = strsplit(rel{i}, '/');
    for p = 1:numel(parts)
        for q = 1:numel(forbidden)
            if ~isempty(regexp(parts{p}, ['^' regexptranslate('wildcard', forbidden{q}) '$'], 'once'))
                error('build_submission:forbidden', 'Forbidden item in zip: %s', rel{i});
            end
        end
    end
end

fprintf('Files in %s:\n', zipFile);
fprintf('  %s\n', rel{:});
info = dir(zipFile);
fprintf('%d files, zip size %.2f MB (%d bytes)\n', numel(rel), info.bytes / 2^20, info.bytes);

function copyOne(srcRoot, dstRoot, relPath)
    src = fullfile(srcRoot, relPath);
    if ~isfile(src), error('build_submission:missing', 'Missing required file: %s', src); end
    dst = fullfile(dstRoot, relPath);
    if ~isfolder(fileparts(dst)), mkdir(fileparts(dst)); end
    [ok, msg] = copyfile(src, dst);
    if ~ok, error('build_submission:copy', 'Copy of %s failed: %s', relPath, msg); end
end

function rmdirIfExists(d)
    if isfolder(d), rmdir(d, 's'); end
end
