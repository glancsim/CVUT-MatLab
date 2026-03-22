function [h, errors] = oofemTestFn(nodes, beams, loads, kinematic, sections, values)
% oofemTestFn  Run OOFEM stability analysis and compare with MATLAB eigenvalues.
%
% Generates OOFEM input from the given model, runs OOFEM via the Python
% runner in tests/oofem/, and compares the resulting eigenvalues with the
% MATLAB eigenvalues provided.
%
% INPUTS:
%   nodes, beams, loads, kinematic, sections — standard FEM model structs
%   values  — MATLAB eigenvalues from stabilitySolverFn (Results.values)
%
% OUTPUTS:
%   h      — figure handle (bar chart of errors per mode)
%   errors — (n×1) relative errors [%] per mode
%
% REQUIREMENTS:
%   tests/oofem/oofem.py  — Python OOFEM input generator + runner
%   tests/oofem/oofem     — OOFEM binary (Linux ELF, invoked via WSL)
%   Python 3 with scipy and numpy installed
%
% (c) S. Glanc, 2025

%--------------------------------------------------------------------------
% Locate tests/oofem/ relative to this source file  (src/../tests/oofem)
%--------------------------------------------------------------------------
srcDir   = fileparts(mfilename('fullpath'));
oofemDir = fullfile(srcDir, '..', 'tests', 'oofem');

oofemPy = fullfile(oofemDir, 'oofem.py');
if ~exist(oofemPy, 'file')
    error('oofemTestFn: oofem.py not found at:\n  %s\nRun fem-stability-matlab/tests/oofem/oofem.py setup.', oofemPy);
end

%--------------------------------------------------------------------------
% Write input.mat into oofemDir so the runner can find it
%--------------------------------------------------------------------------
inputMat = fullfile(oofemDir, 'input.mat');
oofemInputFn(nodes, beams, loads, kinematic, sections, inputMat);

%--------------------------------------------------------------------------
% Locate Python executable (Windows: try 'where python', then fallback)
%--------------------------------------------------------------------------
[~, pyRaw] = system('where python 2>nul');
pyRaw = strtrim(pyRaw);
if isempty(pyRaw)
    % Try python3 (typical on WSL-facing setups)
    [~, pyRaw] = system('where python3 2>nul');
    pyRaw = strtrim(pyRaw);
end
if ~isempty(pyRaw)
    lines  = strsplit(pyRaw, newline);
    pyPath = strtrim(lines{1});
else
    % Last-resort fallback — adjust if Python is elsewhere
    pyPath = 'C:\Install\Python\python.exe';
end
if ~exist(pyPath, 'file')
    error('oofemTestFn: Python not found (%s). Install Python or update the path in oofemTestFn.m.', pyPath);
end

%--------------------------------------------------------------------------
% Run Python runner with oofemDir as working directory.
% oofem.py reads input.mat from cwd and writes eigen.mat there.
%--------------------------------------------------------------------------
prevDir = cd(oofemDir);
cleanupObj = onCleanup(@() cd(prevDir));   %#ok<NASGU>  always restore

cmd = sprintf('"%s" "%s"', pyPath, oofemPy);
[status, out] = system(cmd);
if status ~= 0
    error('oofemTestFn: OOFEM runner returned error %d.\n%s', status, out);
end

%--------------------------------------------------------------------------
% Load eigenvalues from eigen.mat (written by oofem.py)
%--------------------------------------------------------------------------
eigenMat = fullfile(oofemDir, 'eigen.mat');
ref = load(eigenMat, 'eigenvalues');
eigenvalues = ref.eigenvalues;

%--------------------------------------------------------------------------
% Compare positive eigenvalues (ascending order)
%--------------------------------------------------------------------------
posValues   = sort(values(values > 0));             posValues   = posValues(:);
oofemValues = sort(eigenvalues(eigenvalues > 0));   oofemValues = oofemValues(:);
n = min(length(posValues), length(oofemValues));

errors = abs(oofemValues(1:n) - posValues(1:n)) ./ oofemValues(1:n) * 100;
errors = errors(:);

%--------------------------------------------------------------------------
% Plot
%--------------------------------------------------------------------------
h = figure;
bar(1:n, errors);
xlabel('Mód');
ylabel('Chyba (%)');
title('Procentuální chyba oproti OOFEM');
grid on;

end
