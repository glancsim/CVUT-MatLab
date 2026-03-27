% test_input.m — 2D truss Test 1: Symmetric 3-member truss
%
% Geometry:
%         3 (apex)
%        /|\
%       / | \
%  diag1  |  diag2
%     /   |   \
%    /    |    \
%   1-----+-----2   (bottom chord)
%  pin          roller(z)
%
% Nodes: 1=(0,0)  2=(4,0)  3=(2,2)  [m]
% Members:
%   1: 1→3  (left diagonal,  L=2√2, angle=45°)
%   2: 2→3  (right diagonal, L=2√2, angle=135°)
%   3: 1→2  (bottom chord,   L=4,   angle=0°)
%
% Supports:
%   Node 1: pin (ux, uz fixed)
%   Node 2: roller — uz fixed, ux free
%
% Load: F_z = -1000 N at node 3 (downward)
%
% Analytical solution (method of joints at node 3, then node 2):
%   N1 = N2 = -500√2 ≈ -707.107 N  (compression)
%   N3 =  500 N                     (tension)

%% PRŮŘEZY
sections.A = 1e-4;    % [m²]
sections.E = 210e9;   % [Pa]

%% UZLY
nodes.x = [0; 4; 2];
nodes.z = [0; 0; 2];

%% PODPORY
kinematic.x.nodes = [1];    % node 1: pin (ux fixed)
kinematic.z.nodes = [1; 2]; % nodes 1 and 2: uz fixed (2 = roller)

%% PRUTY
members.nodesHead = [1; 2; 1];
members.nodesEnd  = [3; 3; 2];
members.sections  = [1; 1; 1];

%% ZATÍŽENÍ
loads.x.nodes = [];  loads.x.value = [];
loads.z.nodes = [3]; loads.z.value = [-1000];
