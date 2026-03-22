% example_simple_truss.m
%
% 5-node fan truss loaded at the apex (node 4).
%
%   Geometry (x, z):
%     Nodes: 1=(0,0)  2=(6,0)  3=(1,2)  4=(3,2)  5=(5,2)
%
%     3---4---5    (top chord, z=2)
%    / \ / \ /
%   1-----------2  (bottom chord, z=0)
%
%   Members (7):
%     1: 1→2  bottom chord
%     2: 1→3  left diagonal
%     3: 3→4  top chord left
%     4: 4→5  top chord right
%     5: 5→2  right diagonal
%     6: 1→4  left internal diagonal
%     7: 2→4  right internal diagonal
%
%   Supports: node 1 = pin,  node 2 = roller (uz fixed)
%   Load:     Fz = -5000 N at node 4 (apex, downward)
%
% (c) S. Glanc, 2025

clear; close all;
srcDir = fullfile(fileparts(mfilename('fullpath')), '..', 'src');
addpath(srcDir);

%% Input
sections.A = 1e-4;    % [m²]
sections.E = 210e9;   % [Pa]

nodes.x = [0; 6; 1; 3; 5];
nodes.z = [0; 0; 2; 2; 2];

kinematic.x.nodes = [1];
kinematic.z.nodes = [1; 2];

members.nodesHead = [1; 1; 3; 4; 5; 1; 2];
members.nodesEnd  = [2; 3; 4; 5; 2; 4; 4];
members.sections  = ones(7, 1);
members.nmembers  = 7;

loads.x.nodes = [];  loads.x.value = [];
loads.z.nodes = [4]; loads.z.value = [-5000];

%% Solve
[displacements, endForces] = linearSolverFn(sections, nodes, kinematic, members, loads);
N = endForces.local(1, :);
u = full(displacements.global);

%% Print results
fprintf('Member axial forces:\n');
for i = 1:members.nmembers
    if     N(i) >  1e-6, state = 'tension';
    elseif N(i) < -1e-6, state = 'compression';
    else,                 state = 'zero';
    end
    fprintf('  %d (n%d→n%d): N = %10.2f N  [%s]\n', ...
        i, members.nodesHead(i), members.nodesEnd(i), N(i), state);
end
fprintf('\nFree-DOF displacements:\n');
for k = 1:numel(u)
    fprintf('  DOF %d: %.4f mm\n', k, u(k)*1000);
end

%% Plot: geometry with supports and loads
plotTrussFn(nodes, members, loads, kinematic);

%% Plot: deformed shape (exaggerated)
scaleFactor = 200;

% Reconstruct full nodal displacement vector (zeros for constrained DOFs)
nnodes = numel(nodes.x);
u_full = zeros(nnodes * 2, 1);
dof = 0;
for n = 1:nnodes
    if ~ismember(n, kinematic.x.nodes)
        dof = dof + 1;
        u_full(2*n - 1) = u(dof);
    end
    if ~ismember(n, kinematic.z.nodes)
        dof = dof + 1;
        u_full(2*n) = u(dof);
    end
end

nd_x = nodes.x + u_full(1:2:end) * scaleFactor;
nd_z = nodes.z + u_full(2:2:end) * scaleFactor;

figure; hold on; axis equal; grid on;
xlabel('x [m]'); ylabel('z [m]');
title(sprintf('Deformed shape (×%d)  |  blue = tension, red = compression', scaleFactor));

for p = 1:members.nmembers
    h = members.nodesHead(p);  e = members.nodesEnd(p);
    plot([nodes.x(h), nodes.x(e)], [nodes.z(h), nodes.z(e)], '--', ...
         'Color', [0.75 0.75 0.75], 'LineWidth', 1);
    col = 'b';
    if N(p) < -1e-6, col = 'r'; end
    plot([nd_x(h), nd_x(e)], [nd_z(h), nd_z(e)], '-', 'Color', col, 'LineWidth', 2);
end
plot(nd_x, nd_z, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 5);
hold off;
