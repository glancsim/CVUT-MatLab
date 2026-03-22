% example_warren_truss.m
%
% Warren truss (6 panels) with gravity loads at top-chord nodes.
% Axial forces displayed as a colour map on member lines.
%
%   Geometry (x, z):
%     Top chord (z=3):  nodes 7–12  at x = 0.5, 1.5, 2.5, 3.5, 4.5, 5.5
%     Bottom chord (z=0): nodes 1–7 at x = 0, 1, 2, 3, 4, 5, 6
%
%           7   8   9   10  11  12
%          / \ / \ / \ / \ / \ / \
%         1   2   3   4   5   6   7(=13... use 13)
%
%   Use simpler layout: 7 bottom nodes + 6 top nodes (13 nodes total)
%
%         7---8---9--10--11--12
%        / \ / \ / \ / \ / \ / \
%       1---2---3---4---5---6---13
%
%   Members:
%     Bottom chord: 1-2, 2-3, 3-4, 4-5, 5-6, 6-13  (6)
%     Top chord:    7-8, 8-9, 9-10, 10-11, 11-12    (5)
%     Diagonals:    1-7, 7-2, 2-8, 8-3, 3-9, 9-4, 4-10, 10-5, 5-11, 11-6, 6-12, 12-13  (12)
%     Total: 23 members
%
%   Supports: node 1 = pin,  node 13 = roller (uz fixed)
%   Load: Fz = -8000 N at each top chord node (7–12)
%
% (c) S. Glanc, 2025

clear; close all;
srcDir = fullfile(fileparts(mfilename('fullpath')), '..', 'src');
addpath(srcDir);

%% Geometry
% Bottom: nodes 1–7 at (0:6, 0)
% Top:    nodes 8–13 at (0.5:5.5, 3)
xBot = (0:6)';   zBot = zeros(7,1);
xTop = (0.5:5.5)';  zTop = 3*ones(6,1);
nodes.x = [xBot; xTop];
nodes.z = [zBot; zTop];
% Node numbering: bottom = 1..7, top = 8..13

%% Sections
sections.A = 5e-4;    % [m²]
sections.E = 210e9;   % [Pa]

%% Supports
kinematic.x.nodes = [1];
kinematic.z.nodes = [1; 7];

%% Members
% Bottom chord: 1-2, 2-3, 3-4, 4-5, 5-6, 6-7
bHead = (1:6)';  bEnd = (2:7)';
% Top chord: 8-9, 9-10, 10-11, 11-12, 12-13
tHead = (8:12)'; tEnd = (9:13)';
% Diagonals (Warren pattern — alternating):
%   1-8, 8-2, 2-9, 9-3, 3-10, 10-4, 4-11, 11-5, 5-12, 12-6, 6-13
dHead = [1; 8; 2; 9; 3; 10; 4; 11; 5; 12; 6];
dEnd  = [8; 2; 9; 3; 10; 4; 11; 5; 12; 6; 13];

members.nodesHead = [bHead; tHead; dHead];
members.nodesEnd  = [bEnd;  tEnd;  dEnd];
nm = numel(members.nodesHead);
members.sections  = ones(nm, 1);

%% Loads (gravity on top chord nodes 8–12)
loads.x.nodes = [];  loads.x.value = [];
loads.z.nodes = (8:12)';  loads.z.value = -8000 * ones(5, 1);

%% Solve
[displacements, endForces] = linearSolverFn(sections, nodes, kinematic, members, loads);
N = endForces.local(1, :);

%% Report extremes
[~, i_max] = max(N);
[~, i_min] = min(N);
fprintf('Warren truss results:\n');
fprintf('  Max tension:     N = %8.1f N  (member %d: n%d→n%d)\n', ...
    N(i_max), i_max, members.nodesHead(i_max), members.nodesEnd(i_max));
fprintf('  Max compression: N = %8.1f N  (member %d: n%d→n%d)\n', ...
    N(i_min), i_min, members.nodesHead(i_min), members.nodesEnd(i_min));

%% Plot with colour-coded axial forces
figure; hold on; axis equal; grid on;
xlabel('x [m]'); ylabel('z [m]');
title('Warren truss — axial forces (blue = tension, red = compression)');

Nmax = max(abs(N));
cmap = [linspace(1,0,128)', zeros(128,1), linspace(0,1,128)'; ...
        zeros(128,1), zeros(128,1), linspace(1,0,128)'];
% Use simple red-white-blue: negative → red, zero → white, positive → blue
for p = 1:nm
    h_n = members.nodesHead(p);
    e_n = members.nodesEnd(p);
    t = N(p) / (Nmax + eps);   % -1 to +1
    if t >= 0
        col = [1-t, 1-t, 1];   % white → blue
    else
        col = [1, 1+t, 1+t];   % white → red
    end
    lw = 1 + 3*abs(t);          % thicker for higher force
    plot([nodes.x(h_n), nodes.x(e_n)], [nodes.z(h_n), nodes.z(e_n)], ...
         '-', 'Color', col, 'LineWidth', lw);
end

% Node dots
plot(nodes.x, nodes.z, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4);

% Support symbols
xr = max(nodes.x) - min(nodes.x);
zr = max(nodes.z) - min(nodes.z);
Lc = max([xr, zr, 1]);
sz = 0.05 * Lc;
% Pin at node 1
n = 1;
patch([nodes.x(n)-sz, nodes.x(n)+sz, nodes.x(n)], ...
      [nodes.z(n)-sz, nodes.z(n)-sz, nodes.z(n)], ...
      'b', 'FaceColor', [0.6 0.8 1], 'EdgeColor', 'b');
% Roller at node 7
n = 7;
patch([nodes.x(n)-sz, nodes.x(n)+sz, nodes.x(n)], ...
      [nodes.z(n)-sz, nodes.z(n)-sz, nodes.z(n)], ...
      'b', 'FaceColor', [0.6 0.8 1], 'EdgeColor', 'b');
line([nodes.x(n)-sz*1.2, nodes.x(n)+sz*1.2], [nodes.z(n)-sz, nodes.z(n)-sz], ...
     'Color', 'b', 'LineWidth', 2);

% Colorbar legend (manual annotation)
text(0, -0.6, sprintf('Blue = tension (max %.0f N)', Nmax), ...
     'Color', [0 0 0.8], 'FontSize', 9);
text(0, -0.9, sprintf('Red  = compression (min %.0f N)', -Nmax), ...
     'Color', [0.8 0 0], 'FontSize', 9);

hold off;
