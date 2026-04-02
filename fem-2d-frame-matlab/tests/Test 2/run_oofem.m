% run_oofem.m  — OOFEM verification for Test 2 (fixed-fixed beam)
%
% (c) S. Glanc, 2026

testDir = fileparts(mfilename('fullpath'));
srcDir  = fullfile(testDir, '..', '..', 'src');
addpath(srcDir);

run(fullfile(testDir, 'test_input.m'));

fprintf('=== OOFEM Test 2: fixed-fixed beam ===\n');
[errors, d_matlab, d_oofem] = oofemTestFn(nodes, beams, loads, kinematic, sections);

fprintf('\nMidspan (node 2):  uz_MATLAB = %.6e m   uz_OOFEM = %.6e m\n', ...
    d_matlab(2,2), d_oofem(2,2));

% Analytical reference
L = 6;  F = loads.z.value(1);
uz_analytic = F * L^3 / (192 * sections.E * sections.Iz);
fprintf('Analytical:        uz_mid    = %.6e m\n', uz_analytic);
