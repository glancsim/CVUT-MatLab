% generate_references.m  Generate reference_forces.mat for all tests.
%
% Tests 1 and 3: analytical reference (exact for statically determinate trusses).
% Test 2: FEM solution (used as reference — FEM is exact for statically
%         determinate trusses, so this is also analytically exact).
%
% Run this script once after changing test_input.m files.
%
% (c) S. Glanc, 2025

srcDir   = fullfile(fileparts(mfilename('fullpath')), '..', 'src');
testsDir = fileparts(mfilename('fullpath'));
addpath(srcDir);

%% Test 1 — Symmetric 3-member truss
% Analytical: N1=N2=-500*sqrt(2), N3=500  [N]
N_ref = [-500*sqrt(2), -500*sqrt(2), 500];
save(fullfile(testsDir, 'Test 1', 'reference_forces.mat'), 'N_ref');
fprintf('Test 1 reference saved: N = [%.4f, %.4f, %.4f] N\n', N_ref);

%% Test 2 — Pratt truss (FEM reference)
run(fullfile(testsDir, 'Test 2', 'test_input.m'));
[~, endForces] = linearSolverFn(sections, nodes, kinematic, members, loads);
N_ref = endForces.local(1, :);
save(fullfile(testsDir, 'Test 2', 'reference_forces.mat'), 'N_ref');
fprintf('Test 2 reference saved (%d members).\n', numel(N_ref));

%% Test 3 — Simple diagonal truss
% Node 2 is HEAD of member 3 (nodesHead=[1;1;2]).
% Force on HEAD node from member = N*[c,s].
% ΣFx at node 2:  N3*0.8 + 10000 = 0 → N3 = -12500 (compression)
% ΣFz at node 2: -N1*1  + N3*(-0.6)=0 → N1 = N3*0.6 ... wait:
%   member 1 (END node 2): force = N1*(−c,−s)=N1*(0,−1)
%   ΣFz: −N1 − 12500*(−0.6)=0 → N1 = +7500 (tension)
% At node 3 (roller): ΣFx: −N2 + N3*(−c_from_end)=−N2+(−12500)*(−0.8)=0 → N2=10000
N_ref = [7500, 10000, -12500];
save(fullfile(testsDir, 'Test 3', 'reference_forces.mat'), 'N_ref');
fprintf('Test 3 reference saved: N = [%.0f, %.0f, %.0f] N\n', N_ref);

fprintf('\nAll references generated.\n');
