clear; close all; clc;
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

%% PRŮŘEZ — Trubka, ocel

sections.A  = 1.27*1e4*1e-6;           % Plocha [m²]
sections.Iy = 3.66*1e7*1e-12;         % Moment setrvačnosti k ose y [m⁴]
sections.Iz = 3.66*1e7*1e-12;         % Moment setrvačnosti k ose z [m⁴]
sections.Ix = sections.Iy + sections.Iz;         % Polární moment (= Iy + Iz) [m⁴]
sections.E  = 200e9;      % [Pa]
sections.v  = 0.3;

%% UZLY
nodes.x = [0; 0];
nodes.y = [0; 0];
nodes.z = [0; 8];

%% OKRAJOVÉ PODMÍNKY — vetknuté paty (uzly 1 a 4)
kinematic.x.nodes  = [1; 2];
kinematic.y.nodes  = [1; 2];
kinematic.z.nodes  = [1];
kinematic.rx.nodes = [1; 2];
kinematic.ry.nodes = [];
kinematic.rz.nodes = [1; 2];

%% PRUTY
beams.nodesHead = [1];
beams.nodesEnd  = [2];
beams.sections  = [1];
beams.angles    = [0];

%% REFERENCE LOAD — 1 N axial compression at the top node
% --------------------------------------------------------------------------
F_ref = -1000;   % [N]  negative = compression along +z

loads.x.nodes  = [];   loads.x.value  = [];
loads.y.nodes  = [];   loads.y.value  = [];
loads.z.nodes  = [2];  loads.z.value  = [F_ref];
loads.rx.nodes = [];   loads.rx.value = [];
loads.ry.nodes = [];   loads.ry.value = [];
loads.rz.nodes = [];   loads.rz.value = [];

% plotStructureFn(nodes, beams, loads, kinematic) 

ndisc = 2;
%% STABILITY ANALYSIS
% --------------------------------------------------------------------------
Results = stabilitySolverFn(sections, nodes, ndisc, kinematic, beams, loads);

% plotModeShapeFn(nodes, beams, kinematic, Results);

posVals = Results.values(Results.values > 0);
lambda1 = posVals(1);   % smallest positive critical load multiplier
lambda2 = posVals(2);

fprintf('\n');
fprintf('=== McGuire: Matrix structural analysis - Example 9.3 ===\n\n');
fprintf('  Reference critical load   : F_ref = 1137.00 kN\n');
fprintf('\n');
fprintf('  Critical load             : F_crit = %.2f kN\n', abs(lambda1));