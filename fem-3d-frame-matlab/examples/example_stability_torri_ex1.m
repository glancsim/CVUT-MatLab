clear; close all; clc;
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

%% PRŮŘEZ — Trubka, ocel
r_outer = 0.04;
r_inner = 0.035;
sections.A  = pi * (r_outer^2 - r_inner^2);           % Plocha [m²]
sections.Iy = pi/4 * (r_outer^4 - r_inner^4);         % Moment setrvačnosti k ose y [m⁴]
sections.Iz = pi/4 * (r_outer^4 - r_inner^4);         % Moment setrvačnosti k ose z [m⁴]
sections.Ix = pi/2 * (r_outer^4 - r_inner^4);         % Polární moment (= Iy + Iz) [m⁴]
sections.E  = 210e9;      % [Pa]
sections.v  = 0.3;

%% UZLY
nodes.x = [0; 2; 0; 2; 4];
nodes.y = [0; 0; 0; 0; 0];
nodes.z = [0; 0; 2; 2; 2];

%% OKRAJOVÉ PODMÍNKY — vetknuté paty (uzly 1 a 4)
kinematic.x.nodes  = [1; 3];
kinematic.y.nodes  = [1; 3];
kinematic.z.nodes  = [1; 3];
kinematic.rx.nodes = [];
kinematic.ry.nodes = [];
kinematic.rz.nodes = [1; 3];

%% PRUTY
beams.nodesHead = [1; 3; 4; 3; 2; 2];
beams.nodesEnd  = [2; 4; 5; 2; 5; 4];
beams.sections  = [1; 1; 1; 1; 1; 1];
beams.angles    = [0; 0; 0; 0; 0; 0];

%% REFERENCE LOAD — 1 N axial compression at the top node
% --------------------------------------------------------------------------
F_ref = -1000;   % [N]  negative = compression along +z

loads.x.nodes  = [];   loads.x.value  = [];
loads.y.nodes  = [];   loads.y.value  = [];
loads.z.nodes  = [5];  loads.z.value  = [F_ref];
loads.rx.nodes = [];   loads.rx.value = [];
loads.ry.nodes = [];   loads.ry.value = [];
loads.rz.nodes = [];   loads.rz.value = [];

% plotStructureFn(nodes, beams, loads, kinematic) 

ndisc = 16;

%% STABILITY ANALYSIS
% --------------------------------------------------------------------------
Results = stabilitySolverFn(sections, nodes, ndisc, kinematic, beams, loads);

plotModeShapeFn(nodes, beams, kinematic, Results);

posVals = Results.values(Results.values > 0);
lambda1 = posVals(1);   % smallest positive critical load multiplier
lambda2 = posVals(2);

fprintf('\n');
fprintf('=== Pinned-Pinned Column — Linear Buckling Results ===\n\n');
fprintf('  Reference load       : F_ref = %.2f N  (axial compression)\n', abs(F_ref));
fprintf('\n');
fprintf('  Critical load       : F_crit = %.2f N  (axial compression)\n', abs(lambda1));