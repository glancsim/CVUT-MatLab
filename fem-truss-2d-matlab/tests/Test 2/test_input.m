% test_input.m — 2D truss Test 2: Pratt truss (4 panels)
%
% Geometry (in the X-Z plane):
%
%   5----6----7----8    (top chord, z=3)
%   |  x |  x |  x |   (diagonals sloping left-down = Pratt under gravity)
%   1----2----3----4    (bottom chord, z=0)
%
% Nodes (x, z):
%   1=(0,0)  2=(3,0)  3=(6,0)  4=(9,0)   (bottom chord)
%   5=(0,3)  6=(3,3)  7=(6,3)  8=(9,3)   (top chord)
%
% Members:
%   Bottom chord: 1→2, 2→3, 3→4         (horizontal, L=3m)
%   Top chord:    5→6, 6→7, 7→8         (horizontal, L=3m)
%   Verticals:    1→5, 2→6, 3→7, 4→8   (vertical, L=3m)
%   Diagonals:    2→5, 3→6, 4→7        (diagonal, L=3√2, angle=135°)
%
% Supports:
%   Node 1: pin (ux, uz fixed)
%   Node 4: roller (uz fixed, ux free)
%
% Load: F_z = -10000 N at nodes 2, 3 (downward on bottom chord interior)
%
% Member numbering (1-based):
%   1=1→2, 2=2→3, 3=3→4        (bottom)
%   4=5→6, 5=6→7, 6=7→8        (top)
%   7=1→5, 8=2→6, 9=3→7, 10=4→8 (verticals)
%   11=2→5, 12=3→6, 13=4→7    (diagonals)
%
% Analytical solution (method of sections / joints):
% With P = 10000 N at nodes 2 and 3:
%   Reactions: R1z = 15000 N, R4z = 5000 N, R1x = 0
%   Top chord:    N4 = N5 = N6 (need full method-of-sections)
%   Bottom chord: N1 = N2 = N3 (tension)
% Reference values computed by run_reference.m and stored in reference_forces.mat.

%% PRŮŘEZY
sections.A = 5e-4;    % [m²]
sections.E = 210e9;   % [Pa]

%% UZLY
nodes.x = [0; 3; 6; 9;  0; 3; 6; 9];
nodes.z = [0; 0; 0; 0;  3; 3; 3; 3];

%% PODPORY
kinematic.x.nodes = [1];       % node 1: pin
kinematic.z.nodes = [1; 4];    % nodes 1,4: uz fixed (4 = roller)

%% PRUTY — bottom chord, top chord, verticals, diagonals
members.nodesHead = [1; 2; 3;   5; 6; 7;   1; 2; 3; 4;   2; 3; 4];
members.nodesEnd  = [2; 3; 4;   6; 7; 8;   5; 6; 7; 8;   5; 6; 7];
members.sections  = ones(13, 1);

%% ZATÍŽENÍ
loads.x.nodes = [];        loads.x.value = [];
loads.z.nodes = [2; 3];   loads.z.value = [-10000; -10000];
