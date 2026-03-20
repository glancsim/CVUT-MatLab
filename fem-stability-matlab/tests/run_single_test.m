function [errors, sortedValues] = run_single_test(testDir, useOofem)
% run_single_test  Run one stability test and compare against reference.
%
% Loads the test definition from  testDir/test_input.m, resolves cross-section
% properties from sectionsSet.mat, calls stabilitySolverFn to compute critical
% load multipliers, and compares them against a reference.
%
% By default the reference is the pre-computed OOFEM values stored in
% testDir/reference_eigenvalues.mat (no external solver required).
%
% When useOofem=true the comparison is done live against OOFEM via
% oofemTestFn — requires Python + oofem binary in tests/oofem/.
%
% INPUTS:
%   testDir - (char) Absolute or relative path to the test directory.
%             The directory must contain:
%               test_input.m              — defines sections, nodes, ndisc,
%                                           kinematic, beams, loads
%               reference_eigenvalues.mat — variable 'eigenvalues' (from OOFEM)
%             The parent directory of testDir must contain:
%               sectionsSet.mat           — cross-section library
%
% OUTPUTS:
%   errors       - (n x 1) Relative errors [%] for the first n positive
%                  critical load multipliers, compared to reference.
%                  errors(i) = |lambda_MATLAB(i) - lambda_ref(i)| / lambda_ref(i) * 100
%   sortedValues - (10 x 1) All eigenvalues from stabilitySolverFn, sorted
%                  by ascending absolute value.
%
% INPUTS:
%   testDir  - (char) Path to test directory (must contain test_input.m and
%              reference_eigenvalues.mat).
%   useOofem - (logical, optional) If true, compare against live OOFEM run
%              instead of reference_eigenvalues.mat. Default: false.
%
% EXAMPLE:
%   [errors, vals] = run_single_test(fullfile(pwd, 'Test 1'));
%   fprintf('Mean error (ref): %.3f %%\n', mean(errors));
%
%   % Live OOFEM comparison (requires Python + oofem binary):
%   [errors, vals] = run_single_test(fullfile(pwd, 'Test 1'), true);
%
% See also: run_all_tests, stabilitySolverFn, oofemTestFn

if nargin < 2, useOofem = false; end

%% LOAD TEST INPUT
% The test_input.m file sets:  sections.id, nodes, ndisc, kinematic, beams, loads
% We run it inside a temporary function workspace to avoid polluting the caller.

oldDir = cd(testDir);
cleanupObj = onCleanup(@() cd(oldDir));  % always restore working dir

run('test_input.m');   % defines: sections, nodes, ndisc, kinematic, beams, loads

%% RESOLVE CROSS-SECTION PROPERTIES FROM LIBRARY
% test_input.m provides only section indices (sections.id).
% We look up the actual geometric properties in sectionsSet.mat.
%
% sectionsSet.mat contains a table  L  with columns:
%   A    — cross-sectional area [m^2]
%   I_y  — second moment of area (stored as Iz in MATLAB, intentional swap)
%   I_z  — second moment of area (stored as Iy in MATLAB, intentional swap)
%   I_t  — torsional moment of inertia [m^4]

sectionsFile = fullfile(fileparts(mfilename('fullpath')), 'sectionsSet.mat');
cs = importdata(sectionsFile);

sections_full.A  = table2array(cs.L(:, 'A'));
sections_full.Iz = table2array(cs.L(:, 'I_y'));  % intentional swap (see above)
sections_full.Iy = table2array(cs.L(:, 'I_z'));  % intentional swap
sections_full.Ix = table2array(cs.L(:, 'I_t'));

nsec = size(sections.id, 1);
resolvedSections.A  = zeros(nsec, 1);
resolvedSections.Iy = zeros(nsec, 1);
resolvedSections.Iz = zeros(nsec, 1);
resolvedSections.Ix = zeros(nsec, 1);
resolvedSections.E  = zeros(nsec, 1);
resolvedSections.v  = zeros(nsec, 1);

for i = 1:nsec
    id = sections.id(i);
    resolvedSections.A(i)  = sections_full.A(id);
    resolvedSections.Iy(i) = sections_full.Iy(id);
    resolvedSections.Iz(i) = sections_full.Iz(id);
    resolvedSections.Ix(i) = sections_full.Ix(id);
    resolvedSections.E(i)  = 210e9;   % [Pa]  steel
    resolvedSections.v(i)  = 0.3;     % [-]   Poisson's ratio
end

%% RUN STABILITY ANALYSIS
Results = stabilitySolverFn(resolvedSections, nodes, ndisc, kinematic, beams, loads);
sortedValues = Results.values;   % already sorted by stabilitySolverFn

%% COMPARE EIGENVALUES
if useOofem
    %-- Live OOFEM comparison -------------------------------------------
    % Runs oofem.py in tests/oofem/, requires Python + oofem binary.
    [~, errors] = oofemTestFn(nodes, beams, loads, kinematic, resolvedSections, sortedValues);
else
    %-- Reference comparison (no external tools needed) -----------------
    refFile = fullfile(testDir, 'reference_eigenvalues.mat');
    ref     = load(refFile, 'eigenvalues');
    refEigenvalues = ref.eigenvalues;

    posValues = sort(sortedValues(sortedValues > 0));  posValues = posValues(:);
    refValues = sort(refEigenvalues(refEigenvalues > 0)); refValues = refValues(:);
    n         = min(length(posValues), length(refValues));

    errors = abs(refValues(1:n) - posValues(1:n)) ./ refValues(1:n) * 100;
end

end
