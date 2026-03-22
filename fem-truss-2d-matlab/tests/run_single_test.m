function [passed, N_fem, N_ref, err_pct] = run_single_test(testNum)
% run_single_test  Run one truss test and compare axial forces to reference.
%
% USAGE:
%   [passed, N_fem, N_ref, err_pct] = run_single_test(1)
%
% INPUTS:
%   testNum  - integer test number (1, 2, 3, ...)
%
% OUTPUTS:
%   passed   - true if max relative error < tolerance
%   N_fem    - (1×nmembers) computed axial forces [N]
%   N_ref    - (1×nmembers) reference axial forces [N]
%   err_pct  - (1×nmembers) relative error [%]
%
% (c) S. Glanc, 2025

TOL_PCT = 0.001;   % 0.001 % tolerance (FEM is exact for statically determinate trusses)

% Paths
testDir = fullfile(fileparts(mfilename('fullpath')), sprintf('Test %d', testNum));
srcDir  = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'src');
addpath(srcDir);

% Load test input
run(fullfile(testDir, 'test_input.m'));

% Solve
[~, endForces] = linearSolverFn(sections, nodes, kinematic, members, loads);
N_fem = endForces.local(1, :);   % row 1 = axial force at head end

% Load reference
refFile = fullfile(testDir, 'reference_forces.mat');
if ~isfile(refFile)
    error('Reference file not found: %s\nRun generate_reference.m first.', refFile);
end
ref = load(refFile, 'N_ref');
N_ref = ref.N_ref(:)';

% Compute errors
% Use absolute reference for normalisation; if N_ref ~ 0 use absolute error
denom = max(abs(N_ref), 1);   % avoid div/0 for zero-force members
err_pct = abs(N_fem - N_ref) ./ denom * 100;

maxErr = max(err_pct);
passed = maxErr < TOL_PCT;

% Report
fprintf('Test %d: ', testNum);
if passed
    fprintf('PASSED  (max err = %.4e %%)\n', maxErr);
else
    fprintf('FAILED  (max err = %.4f %%)\n', maxErr);
    fprintf('  Member   N_fem [N]     N_ref [N]    err [%%]\n');
    for i = 1:numel(N_fem)
        marker = '';
        if err_pct(i) >= TOL_PCT, marker = ' <--'; end
        fprintf('  %6d   %12.4f   %12.4f   %8.4f%s\n', ...
            i, N_fem(i), N_ref(i), err_pct(i), marker);
    end
end
end
