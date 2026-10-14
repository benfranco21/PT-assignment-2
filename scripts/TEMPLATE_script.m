% TEMPLATE_SCRIPT Copy this header and root-resolution block into every new Part II script.
%
%   File:         TEMPLATE_script.m
%   Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
%   Version:      PT_A2_2026_FRNBEN003_v1.0
%   Author:       Benjamin Franco (FRNBEN003)
%   Date:         2026-10-14
%   Purpose:      Development template. Shows the header and the lines that let a script in
%                 scripts/ run on its own, without run_all and from any current folder.
%   Inputs:       None (replace with the real inputs, e.g. data/raw/...).
%   Outputs:      Prints the project root (replace with the real outputs).
%   Dependencies: Base MATLAB only. Uses startup.m.
%
%   Copy everything between the two marker lines into the new script, rename the file,
%   and rewrite the header (File, Date, Purpose, Inputs, Outputs, Dependencies).

% ---- BEGIN standalone block ----------------------------------------------
projectRoot = fileparts(fileparts(mfilename('fullpath')));      % scripts/ is one level below the root
if ~any(strcmp(strsplit(path, pathsep), fullfile(projectRoot, 'functions')))
    run(fullfile(projectRoot, 'startup.m'));                     % functions/ not on the path yet
end
% ---- END standalone block ------------------------------------------------

fprintf('TEMPLATE_script: project root is %s\n', projectRoot);
