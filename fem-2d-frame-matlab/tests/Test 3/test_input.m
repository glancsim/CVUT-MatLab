% test_input.m — 2D Frame Test 3: Portal frame with hinge on beam
%
% Geometry (XZ plane):
%   Node 1 (0,0) — column base, fully fixed
%   Node 2 (0,4) — column top / left beam end
%   Node 3 (5,4) — beam right end / right column top
%   Node 4 (5,0) — column base, fully fixed
%
% Beams:
%   Beam 1: column 1→2  (vertical, left)
%   Beam 2: column 4→3  (vertical, right)
%   Beam 3: beam   2→3  (horizontal)  — HINGE at head (node 2)
%
% Load: Fz = -5 000 N at node 3 (right beam end, downward)
%
% Section: A=2e-3 m², Iz=2e-5 m⁴, E=210e9 Pa
%
% This test verifies:
%   • beams.releases   (kloubové uložení prutu 3 na uzlu 2)
%   • portal frame geometry
%   Reference: solved numerically (FEM reference stored at first run)

%% PRŮŘEZY
sections.A  = 2e-3;    % [m²]
sections.Iz = 2e-5;    % [m⁴]
sections.E  = 210e9;   % [Pa]

%% UZLY
nodes.x = [0; 0; 5; 5];
nodes.z = [0; 4; 4; 0];

%% PODPORY — vetknutí v uzlech 1 a 4
kinematic.x.nodes  = [1; 4];
kinematic.z.nodes  = [1; 4];
kinematic.ry.nodes = [1; 4];

%% PRUTY
beams.nodesHead = [1; 4; 2];
beams.nodesEnd  = [2; 3; 3];
beams.sections  = [1; 1; 1];

%% KLOUBY — prut 3, kloub na hlavovém konci (uzel 2)
beams.releases = false(3, 2);
beams.releases(3, 1) = true;

%% ZATÍŽENÍ — svislá síla -5000 N v uzlu 3
loads.x.nodes  = [];  loads.x.value  = [];
loads.z.nodes  = [3]; loads.z.value  = [-5000];
loads.ry.nodes = [];  loads.ry.value = [];
