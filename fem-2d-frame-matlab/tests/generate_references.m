% generate_references.m  Generate reference files for all 2D frame tests.
%
% For all tests the full FEM displacement vector is stored as reference.
% Tests 1 and 2 are additionally verified against analytical solutions
% during generation.
%
% Run this once before running run_all_tests.m (or let run_all_tests call it).
%
% (c) S. Glanc, 2026

srcDir = fullfile(fileparts(mfilename('fullpath')), '..', 'src');
addpath(srcDir);

ndisc_ref = 10;   % discretisation used for all references

% =========================================================================
% Test 1 — Cantilever beam: compare FEM vs analytical, store FEM
% =========================================================================
td = fullfile(fileparts(mfilename('fullpath')), 'Test 1');
run(fullfile(td, 'test_input.m'));

[displacements, ~] = linearSolverFn(sections, nodes, ndisc_ref, kinematic, beams, loads);
d_ref = full(displacements.global);
save(fullfile(td, 'reference.mat'), 'd_ref');

% Analytical check (Euler-Bernoulli cantilever)
L   = 4;   F = -10000;
uz_analytic = F * L^3 / (3 * sections.E * sections.Iz);
ry_analytic = F * L^2 / (2 * sections.E * sections.Iz);
% Node 2 DOFs are always codes 1,2,3  (node 1 fully fixed → no free DOFs)
err_uz = abs(d_ref(2) - uz_analytic) / abs(uz_analytic) * 100;
err_ry = abs(d_ref(3) - ry_analytic) / abs(ry_analytic) * 100;
fprintf('Test 1: uz_tip FEM=%.6f  analytic=%.6f  err=%.4g%%\n', d_ref(2), uz_analytic, err_uz);
fprintf('        ry_tip FEM=%.6f  analytic=%.6f  err=%.4g%%\n', d_ref(3), ry_analytic, err_ry);

% =========================================================================
% Test 2 — Fixed-fixed beam: compare FEM vs analytical, store FEM
% =========================================================================
td = fullfile(fileparts(mfilename('fullpath')), 'Test 2');
run(fullfile(td, 'test_input.m'));

[displacements, ~] = linearSolverFn(sections, nodes, ndisc_ref, kinematic, beams, loads);
d_ref = full(displacements.global);
save(fullfile(td, 'reference.mat'), 'd_ref');

% Analytical check (fixed-fixed beam, midspan load)
L2  = 6;   F2 = -12000;
uz_analytic2 = F2 * L2^3 / (192 * sections.E * sections.Iz);
err_uz2 = abs(d_ref(2) - uz_analytic2) / abs(uz_analytic2) * 100;
fprintf('Test 2: uz_mid FEM=%.6f  analytic=%.6f  err=%.4g%%\n', d_ref(2), uz_analytic2, err_uz2);

% =========================================================================
% Test 3 — Portal frame with hinge: FEM reference
% =========================================================================
td = fullfile(fileparts(mfilename('fullpath')), 'Test 3');
run(fullfile(td, 'test_input.m'));

[displacements, ~] = linearSolverFn(sections, nodes, ndisc_ref, kinematic, beams, loads);
d_ref = full(displacements.global);
save(fullfile(td, 'reference.mat'), 'd_ref');
fprintf('Test 3: FEM reference saved (%d free DOFs)\n', numel(d_ref));

fprintf('\nAll references generated.\n');
