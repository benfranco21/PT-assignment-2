% STARTUP Add the project functions/ folder and all its subfolders to the MATLAB path.
%
%   File:         startup.m
%   Project:      STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
%   Version:      PT_A2_2026_FRNBEN003_v1.0
%   Author:       Benjamin Franco (FRNBEN003)
%   Date:         2026-10-14
%   Purpose:      Put functions/ (data, portfolio, performance, diagnostics) on the path.
%                 The location is taken from this file's own location, not the current folder.
%   Inputs:       None.
%   Outputs:      Modified MATLAB path for the current session (not saved).
%   Dependencies: Base MATLAB only.

projectRoot = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(projectRoot, 'functions')));
