% example_portal_frame.m  — 2D portal frame with hinged beam
%
% Geometry (XZ plane):
%
%   2 o=======[HINGE]=========o 3
%     |                       |
%     |  (column L=4m)        |  (column L=4m)
%     |                       |
%   1 ▓▓▓                 ▓▓▓ 4
%
% Nodes:
%   1 = (0, 0)  — fixed base (left column)
%   2 = (0, 4)  — left column top
%   3 = (6, 4)  — right column top
%   4 = (6, 0)  — fixed base (right column)
%
% Beams:
%   Beam 1: left column  1→2
%   Beam 2: right column 4→3
%   Beam 3: cross beam   2→3  — moment release (hinge) at node 2
%
% Load: Fz = -20 kN at node 3 (downward)
%
% Usage:
%   cd fem-2d-frame-matlab/examples
%   example_portal_frame
%
% (c) S. Glanc, 2026

addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

%% Section — steel HEB 200 (approx)
sections.A  = 7.81e-3;    % [m²]
sections.Iz = 5.696e-5;   % [m⁴]
sections.E  = 210e9;      % [Pa]

%% Nodes
nodes.x = [0; 0; 6; 6];
nodes.z = [0; 4; 4; 0];

%% Supports — fully fixed bases
kinematic.x.nodes  = [1; 4];
kinematic.z.nodes  = [1; 4];
kinematic.ry.nodes = [1; 4];

%% Beams
beams.nodesHead = [1; 4; 2];
beams.nodesEnd  = [2; 3; 3];
beams.sections  = [1; 1; 1];

% Hinge on cross-beam at node 2 (head end of beam 3)
beams.releases = false(3, 2);
beams.releases(3, 1) = true;

%% Loads
loads.x.nodes  = [];  loads.x.value  = [];
loads.z.nodes  = [3]; loads.z.value  = [-20000];
loads.ry.nodes = [];  loads.ry.value = [];

%% Solve
ndisc = 5;
[displacements, endForces] = linearSolverFn(sections, nodes, ndisc, kinematic, beams, loads);

%% Results
fprintf('=== Portal Frame with Hinge ===\n');
d = full(displacements.global);
fprintf('Free-DOF displacements:\n');
fprintf('  Node 2: ux=%.4e m,  uz=%.4e m,  ry=%.4e rad\n', d(1), d(2), d(3));
fprintf('  Node 3: ux=%.4e m,  uz=%.4e m,  ry=%.4e rad\n', d(4), d(5), d(6));

fprintf('\nEnd forces (beam 3 = cross-beam, element 1 = head):\n');
% endForces.local rows: N, Vz, My  at head (1-3) and end (4-6)
e3_start = ndisc*2 + 1;   % first element of beam 3
f = endForces.local(:, e3_start);
fprintf('  N  = %+.2f N\n',   f(1));
fprintf('  Vz = %+.2f N\n',   f(2));
fprintf('  My = %+.2f N·m  (should be ≈ 0 → hinge)\n', f(3));

%% Plot
plotFrameFn(nodes, beams, loads, kinematic, 'Labels', true);
title('Portal frame with hinge (2D)');
