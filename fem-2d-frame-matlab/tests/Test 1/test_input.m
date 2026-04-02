% test_input.m — 2D Frame Test 1: Cantilever beam
%
% Geometry (XZ plane):
%   Node 1 (0,0) — fully fixed (ux, uz, ry)
%   Node 2 (4,0) — free (tip)
%
% Beam: 1→2, length L = 4 m
% Section: IPE 200 equivalent (b.o.m.): A=2.85e-3 m², Iz=1.943e-5 m⁴, E=210e9 Pa
%
% Load: Fz = -10 000 N at node 2 (downward)
%
% Analytical solution (Euler-Bernoulli cantilever):
%   uz_tip = F*L³ / (3*E*I) = 10000 * 4³ / (3 * 210e9 * 1.943e-5)
%          = 10000*64 / (12285900) ≈ 0.052089 m
%   ry_tip = F*L² / (2*E*I) = 10000 * 16 / (3*210e9*1.943e-5/2)
%   ry_tip = F*L² / (2*E*I) ≈ 0.019533 rad
%   My_support = F * L = 40 000 N·m

%% PRŮŘEZY
sections.A  = 2.85e-3;   % [m²]
sections.Iz = 1.943e-5;  % [m⁴]
sections.E  = 210e9;     % [Pa]

%% UZLY
nodes.x = [0; 4];
nodes.z = [0; 0];

%% PODPORY — vetknutí v uzlu 1
kinematic.x.nodes  = [1];
kinematic.z.nodes  = [1];
kinematic.ry.nodes = [1];

%% PRUTY
beams.nodesHead = [1];
beams.nodesEnd  = [2];
beams.sections  = [1];

%% ZATÍŽENÍ — svislá síla -10 000 N v uzlu 2
loads.x.nodes  = [];  loads.x.value  = [];
loads.z.nodes  = [2]; loads.z.value  = [-10000];
loads.ry.nodes = [];  loads.ry.value = [];
