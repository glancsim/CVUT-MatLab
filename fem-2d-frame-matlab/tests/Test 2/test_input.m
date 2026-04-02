% test_input.m — 2D Frame Test 2: Fixed-fixed beam with midspan load
%
% Geometry (XZ plane):
%   Node 1 (0,0) — fully fixed
%   Node 2 (3,0) — midspan, free
%   Node 3 (6,0) — fully fixed
%
% Beams: 1→2 and 2→3 (length 3 m each), total L = 6 m
%
% Section: A=1e-3 m², Iz=1e-5 m⁴, E=210e9 Pa
%
% Load: Fz = -12 000 N at node 2 (midspan, downward)
%
% Analytical solution for fixed-fixed beam with midspan point load F, span L:
%   uz_mid    = F * L³ / (192 * E * I)
%             = 12000 * 216 / (192 * 210e9 * 1e-5) ≈ 0.006429 m
%   M_support = F * L / 8 = 12000 * 6 / 8 = 9000 N·m
%   M_midspan = F * L / 8 = 9000 N·m

%% PRŮŘEZY
sections.A  = 1e-3;    % [m²]
sections.Iz = 1e-5;    % [m⁴]
sections.E  = 210e9;   % [Pa]

%% UZLY
nodes.x = [0; 3; 6];
nodes.z = [0; 0; 0];

%% PODPORY
kinematic.x.nodes  = [1; 3];
kinematic.z.nodes  = [1; 3];
kinematic.ry.nodes = [1; 3];

%% PRUTY
beams.nodesHead = [1; 2];
beams.nodesEnd  = [2; 3];
beams.sections  = [1; 1];

%% ZATÍŽENÍ — svislá síla v uzlu 2
loads.x.nodes  = [];  loads.x.value  = [];
loads.z.nodes  = [2]; loads.z.value  = [-12000];
loads.ry.nodes = [];  loads.ry.value = [];
