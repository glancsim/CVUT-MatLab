% test_input.m — 2D truss Test 3: Simple diagonal truss (exact hand-calculation)
%
% Geometry:
%
%   2
%   |\
%   | \  diag (member 3)
%   |  \
%   1---3
%
% Nodes: 1=(0,0)  2=(0,3)  3=(4,0)  [m]
% Members:
%   1: 1→2  (vertical,  L=3, angle=90°)
%   2: 1→3  (horizontal, L=4, angle=0°)
%   3: 2→3  (diagonal,  L=5, angle=arctan(-3/4) below horizontal)
%
% Supports:
%   Node 1: pin (ux, uz fixed)
%   Node 3: roller (uz fixed, ux free)
%
% Load: F_x = 10000 N (horizontal) at node 2
%
% Analytical solution (method of joints):
%   Member 3 (diagonal 2→3): Δx=4, Δz=-3, L=5, c=4/5=0.8, s=-3/5=-0.6
%
%   Node 2 is HEAD of member 3 (nodesHead=[1;1;2]).
%   Force on HEAD node from member: N*[c, s].
%   Node 2 is END  of member 1 (nodesEnd=[2;3;3]).
%   Force on END  node from member: N*[-c, -s].
%
%   At node 2 (free):
%     ΣFx: N3*c3 + 10000 = 0   →  N3*0.8 = -10000  →  N3 = -12500 N
%     ΣFz: N1*(-s1) + N3*s3 = 0  →  -N1*1 + (-12500)*(-0.6) = 0  →  N1 = +7500 N
%   At node 3 (roller, ux free):
%     ΣFx: N2*(-c2) + N3*(-c3_at_end) = 0
%          member 2 END: -N2*1;   member 3 END: -N3*(-0.8) = +N3*0.8
%          -10000 + (-12500)*(-0.8) = -10000 + 10000 = 0  →  N2 = 10000 N  ✓
%
%   Final: N1 = +7500 N (tension), N2 = 10000 N (tension), N3 = -12500 N (compression)
%
%   Check reactions:
%   At node 1: N1*[0,1] + N2*[1,0] → R1 = [-N1*0 - N2*1, -N1*1 - N2*0] = [-10000, 7500]
%   At node 3: R3z = -N3*s_at_node3... (roller, only z reaction)

%% PRŮŘEZY
sections.A = 1e-3;    % [m²]
sections.E = 210e9;   % [Pa]

%% UZLY
nodes.x = [0; 0; 4];
nodes.z = [0; 3; 0];

%% PODPORY
kinematic.x.nodes = [1];       % node 1: pin
kinematic.z.nodes = [1; 3];    % node 1 (pin) + node 3 (roller)

%% PRUTY
members.nodesHead = [1; 1; 2];
members.nodesEnd  = [2; 3; 3];
members.sections  = [1; 1; 1];

%% ZATÍŽENÍ
loads.x.nodes = [2];  loads.x.value = [10000];   % horizontal force at node 2
loads.z.nodes = [];   loads.z.value = [];
