%% example_stability_column.m
% ==========================================================================
%  EXAMPLE 2 — Linear buckling analysis of a pinned-pinned column (Euler)
% ==========================================================================
%
% A straight column of length L = 4 m, pinned at both ends, loaded by
% a unit compressive force F_ref = 1 N along its axis.
% The first critical load equals the Euler buckling load:
%
%   F_cr = pi^2 * E * I_min / L^2
%
% The stability analysis returns the critical load multiplier lambda_1
% such that  F_critical = lambda_1 * F_ref.
%
%   [pin]        F_ref = 1 N (axial, downward)
%     |               |
%     |               v
%     o --- column ---o   (length L = 4 m, axis along global z)
%     |
%   [pin]
%
% Running this example:
%   1. Make sure  src/  is on the MATLAB path, e.g.:
%        addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'))
%   2. Run the script:  example_stability_column
% ==========================================================================

clear; close all; clc;
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

%% CROSS-SECTION PROPERTIES (HEB 120 profile, steel)
% --------------------------------------------------------------------------
sections.A  = 34.01e-4;    % [m^2]  cross-sectional area
sections.Iy = 864.4e-8;    % [m^4]  moment of inertia about y-axis (stronger)
sections.Iz = 317.5e-8;    % [m^4]  moment of inertia about z-axis (weaker)
sections.Ix = 13.84e-8;    % [m^4]  torsional moment
sections.E  = 210e9;       % [Pa]   Young's modulus (steel)
sections.v  = 0.3;         % [-]    Poisson's ratio

L = 4;   % [m]  column length

%% NODES
% --------------------------------------------------------------------------
% Column oriented along the global z-axis: bottom = node 1, top = node 2.
nodes.x = [0; 0];   % [m]
nodes.y = [0; 0];   % [m]
nodes.z = [0; L];   % [m]

%% DISCRETIZATION
% --------------------------------------------------------------------------
ndisc = 20;   % elements per beam (higher = more accurate eigenvalues)

%% BOUNDARY CONDITIONS (pinned-pinned column)
% --------------------------------------------------------------------------
% Node 1 (bottom): fix all translations, fix rotations about x and y.
%                  Allow rotation about z (pin in x-y plane).
% Node 2 (top)   : fix all translations, fix rotations about x and y.
%                  Allow rotation about z (pin in x-y plane).
% Both ends are free to rotate about the beam axis (no torsion restraint).

kinematic.x.nodes  = [1; 2];
kinematic.y.nodes  = [1; 2];
kinematic.z.nodes  = [1];     % fix axial displacement only at base
kinematic.rx.nodes = [1; 2];
kinematic.ry.nodes = [1; 2];
kinematic.rz.nodes = [];      % no rotational restraint about z (pinned)

%% BEAMS
% --------------------------------------------------------------------------
beams.nodesHead = [1];
beams.nodesEnd  = [2];
beams.sections  = [1];
beams.angles    = [0];

%% REFERENCE LOAD — 1 N axial compression at the top node
% --------------------------------------------------------------------------
F_ref = -1;   % [N]  negative = compression along +z

loads.x.nodes  = [];   loads.x.value  = [];
loads.y.nodes  = [];   loads.y.value  = [];
loads.z.nodes  = [2];  loads.z.value  = [F_ref];
loads.rx.nodes = [];   loads.rx.value = [];
loads.ry.nodes = [];   loads.ry.value = [];
loads.rz.nodes = [];   loads.rz.value = [];

%% STABILITY ANALYSIS
% --------------------------------------------------------------------------
Results = stabilitySolverFn(sections, nodes, ndisc, kinematic, beams, loads);

%% ANALYTICAL REFERENCE (Euler, pin-pin, weak axis)
% --------------------------------------------------------------------------
F_cr_Iz = pi^2 * sections.E * sections.Iz / L^2;   % weak axis (z)
F_cr_Iy = pi^2 * sections.E * sections.Iy / L^2;   % strong axis (y)

%% RESULTS
% --------------------------------------------------------------------------
% Results.values contains eigenvalues sorted by ascending absolute value.
% Positive eigenvalues correspond to buckling under the given (compressive) load.
% lambda * F_ref = critical force  =>  F_critical = lambda * 1 N = lambda N.

posVals = Results.values(Results.values > 0);
lambda1 = posVals(1);   % smallest positive critical load multiplier
lambda2 = posVals(2);

fprintf('\n');
fprintf('=== Pinned-Pinned Column — Linear Buckling Results ===\n\n');
fprintf('  Reference load       : F_ref = %.1f N  (axial compression)\n', abs(F_ref));
fprintf('\n');
fprintf('  --- Mode 1 (weak axis, z) ---\n');
fprintf('    lambda_1   (FEM)   : %12.2f\n', lambda1);
fprintf('    F_cr,1     (FEM)   : %12.2f N\n', lambda1 * abs(F_ref));
fprintf('    F_cr,1     (Euler) : %12.2f N\n', F_cr_Iz);
fprintf('    Relative error     : %8.4f %%\n', ...
        abs(lambda1 * abs(F_ref) - F_cr_Iz) / F_cr_Iz * 100);
fprintf('\n');
fprintf('  --- Mode 2 (strong axis, y) ---\n');
fprintf('    lambda_2   (FEM)   : %12.2f\n', lambda2);
fprintf('    F_cr,2     (FEM)   : %12.2f N\n', lambda2 * abs(F_ref));
fprintf('    F_cr,2     (Euler) : %12.2f N\n', F_cr_Iy);
fprintf('    Relative error     : %8.4f %%\n', ...
        abs(lambda2 * abs(F_ref) - F_cr_Iy) / F_cr_Iy * 100);
fprintf('\n');
fprintf('  All positive eigenvalues (lambda = F_cr / F_ref):\n');
fprintf('    ');
fprintf('%12.2f', posVals(1:min(end,6)));
fprintf('\n\n');

%% BUCKLING MODES PLOT
% --------------------------------------------------------------------------
figure('Name', 'Column — First two buckling modes', 'Position', [100 100 600 500]);

% The buckling mode shapes are in Results.vectors.
% Each column is an eigenvector with the free-DOF ordering used by the solver.
% For a visual approximation, we show the lateral displacement component.
% (A complete mode-shape plot requires post-processing the DOF vector —
%  this simplified version uses the eigenvalue bar chart instead.)

allPos = sort(Results.values(Results.values > 0));
nShow  = min(length(allPos), 6);
bar(1:nShow, allPos(1:nShow));
xlabel('Mode index');
ylabel('\lambda_i  (critical load multiplier)');
title({'Pinned-pinned column', 'Critical load multipliers  \lambda_i'});
hold on;
yline(F_cr_Iz / abs(F_ref), 'r--', 'Euler (weak)', 'LabelVerticalAlignment', 'bottom');
yline(F_cr_Iy / abs(F_ref), 'b--', 'Euler (strong)', 'LabelVerticalAlignment', 'bottom');
grid on;
legend('FEM \lambda_i', 'Euler weak axis', 'Euler strong axis', 'Location', 'northwest');
