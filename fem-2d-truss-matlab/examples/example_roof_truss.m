% example_roof_truss.m
%
% Pitched roof truss (sedlový střešní vazník) imported from AutoCAD.
% 29 nodes, 55 members — 2D in the XZ plane.
%
%   Geometry:
%     Span ~23.26 m, apex at (11.63, 2.05)
%     Bottom chord (z=0): 12 nodes at x = 0.59 .. 22.67
%     Top chord (z>0):    17 nodes from (0, 0.59) through apex to (23.26, 0.59)
%
%   Members:
%     Bottom chord:          11 members (section group 1)
%     Top chord:             16 members (section group 2)
%     Diagonals + verticals: 28 members (section group 3)
%     Total: 55 members
%
%   Supports: pin at node 1 (x=0.59), roller at node 12 (x=22.67)
%   Load: Fz = -5000 N at each top-chord node (17 nodes)
%
% (c) S. Glanc, 2026

clear; close all;
srcDir = fullfile(fileparts(mfilename('fullpath')), '..', 'src');
addpath(srcDir);

%% Nodes (29 nodes)
% Bottom chord (z=0): nodes 1–12, sorted left to right
xBot = [0.59; 2.09; 3.6; 5.09; 7.35; 10.06; 13.2; 15.92; 18.17; 19.66; 21.17; 22.67];
zBot = zeros(12, 1);

% Top chord (z>0): nodes 13–29, sorted left to right
xTop = [0; 1.35; 2.85; 4.35; 5.85; 7.35; 8.85; 10.06; 11.63; 13.2; 14.41; 15.92; 17.41; 18.91; 20.41; 21.91; 23.26];
zTop = [0.59; 0.76; 0.95; 1.14; 1.33; 1.51; 1.7; 1.85; 2.05; 1.85; 1.7; 1.51; 1.33; 1.14; 0.95; 0.76; 0.59];

nodes.x = [xBot; xTop];
nodes.z = [zBot; zTop];
% Node numbering:
%   1–12  = bottom chord (z=0)
%   13–29 = top chord (z>0)
%   Node 21 = apex (11.63, 2.05)

%% Sections — 3 groups
%   1 = bottom chord (L 80x8)
%   2 = top chord    (L 80x8)
%   3 = diagonals + verticals (L 50x5)
E = 210e9;  % [Pa] steel
sections.A = [12.3e-4; 12.3e-4; 4.8e-4];   % [m²]
sections.E = [E; E; E];

%% Supports
% Pin at node 1 (x=0.59, z=0) — fixes ux and uz
% Roller at node 12 (x=22.67, z=0) — fixes uz only
kinematic.x.nodes = [13];
kinematic.z.nodes = [13; 29];

%% Members (55 total)
% --- Bottom chord (11 members, section 1) ---
botHead = [6; 9; 10; 11; 12;  8;  5; 4; 3; 2; 1];
botEnd  = [7; 8;  9; 10; 11;  7;  6; 5; 4; 3; 2];

% --- Top chord (16 members, section 2) ---
topHead = [22; 23; 24; 25; 26; 27; 28; 29; 20; 19; 18; 17; 16; 15; 14; 13];
topEnd  = [21; 22; 23; 24; 25; 26; 27; 28; 21; 20; 19; 18; 17; 16; 15; 14];

% --- Diagonals (24 members, section 3) ---
diagHead = [23;  8; 25;  9; 26; 10; 27; 11; 28; 12; 29;  7; 13;  6; 19;  5; 17;  4; 16;  3; 15;  2; 14;  1];
diagEnd  = [ 7; 23;  8; 25;  9; 26; 10; 27; 11; 28; 12; 21;  1; 21;  6; 19;  5; 17;  4; 16;  3; 15;  2; 14];

% --- Verticals (4 members, section 3) ---
vertHead = [24; 20; 18; 22];
vertEnd  = [ 8;  6;  5;  7];

members.nodesHead = [botHead; topHead; diagHead; vertHead];
members.nodesEnd  = [botEnd;  topEnd;  diagEnd;  vertEnd];
nm = numel(members.nodesHead);

% Section assignment: 1=bottom, 2=top, 3=diag+vert
members.sections = [1*ones(numel(botHead),1);
                    2*ones(numel(topHead),1);
                    3*ones(numel(diagHead),1);
                    3*ones(numel(vertHead),1)];

%% Loads — uniform Fz on all top-chord nodes (13–29)
F = 5000;  % [N]
loads.x.nodes = [];  loads.x.value = [];
loads.z.nodes = (13:29)';
loads.z.value = -F * ones(17, 1);

%% Plot: geometry with supports and loads
plotTrussFn(nodes, members, loads, kinematic, 'Labels', true);

%% Solve
[displacements, endForces] = linearSolverFn(sections, nodes, kinematic, members, loads);
N = endForces.local(1, :);

%% Report
[~, i_max] = max(N);
[~, i_min] = min(N);
fprintf('Roof truss results (29 nodes, 55 members):\n');
fprintf('  Max tension:     N = %8.1f N  (member %d: n%d -> n%d)\n', ...
    N(i_max), i_max, members.nodesHead(i_max), members.nodesEnd(i_max));
fprintf('  Max compression: N = %8.1f N  (member %d: n%d -> n%d)\n', ...
    N(i_min), i_min, members.nodesHead(i_min), members.nodesEnd(i_min));
fprintf('  Total load:      Fz = %.0f N\n', sum(loads.z.value));
fprintf('  Max deflection:  uz = %.4f mm\n', ...
    min(full(displacements.global)) * 1000);