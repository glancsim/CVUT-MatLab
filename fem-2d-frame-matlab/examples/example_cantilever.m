% example_cantilever.m  — Simple cantilever beam with tip load
%
% Node 1 (0,0) fully fixed, Node 2 (3,0) free.
% Fz = -5000 N at tip.
%
% Analytical:
%   uz_tip = F*L³/(3EI)
%   My_support = F*L = 15000 N·m
%
% (c) S. Glanc, 2026

addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

%% Section
sections.A  = 1e-3;    % [m²]
sections.Iz = 1e-5;    % [m⁴]
sections.E  = 210e9;   % [Pa]

%% Nodes
nodes.x = [0; 3];
nodes.z = [0; 0];

%% Supports
kinematic.x.nodes  = [1];
kinematic.z.nodes  = [1];
kinematic.ry.nodes = [1];

%% Beams
beams.nodesHead = [1];
beams.nodesEnd  = [2];
beams.sections  = [1];

%% Loads
loads.x.nodes  = [];  loads.x.value  = [];
loads.z.nodes  = [2]; loads.z.value  = [-5000];
loads.ry.nodes = [];  loads.ry.value = [];

%% Solve
[displacements, endForces] = linearSolverFn(sections, nodes, 1, kinematic, beams, loads);

%% Results
F = -5000;  L = 3;  E = sections.E;  I = sections.Iz;
uz_analytic = F * L^3 / (3 * E * I);
My_analytic = F * L;

d = full(displacements.global);
fprintf('=== Cantilever Beam ===\n');
fprintf('  uz_tip  FEM      = %.6f m\n',   d(2));
fprintf('  uz_tip  analytic = %.6f m\n',   uz_analytic);
fprintf('  My at support FEM      = %.2f N·m\n', endForces.local(3, 1));
fprintf('  My at support analytic = %.2f N·m\n', My_analytic);

%% Plot
plotFrameFn(nodes, beams, loads, kinematic, 'Labels', true);
title('Cantilever beam');
