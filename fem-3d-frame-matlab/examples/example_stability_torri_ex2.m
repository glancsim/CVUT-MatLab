clear; close all; clc;
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

%% PRŮŘEZ — Trubka, ocel
r_outer = [5.6793; 5.0566; 0.0001; 4.8887; 0.0001; 6.0175; 4.1126] * 1e-2;
r_inner = r_outer*0.9;
sections.A  = pi .* (r_outer.^2 - r_inner.^2);           % Plocha [m²]
sections.Iy = pi/4 * (r_outer.^4 - r_inner.^4);         % Moment setrvačnosti k ose y [m⁴]
sections.Iz = pi/4 * (r_outer.^4 - r_inner.^4);         % Moment setrvačnosti k ose z [m⁴]
sections.Ix = pi/2 * (r_outer.^4 - r_inner.^4);         % Polární moment (= Iy + Iz) [m⁴]
sections.E  = ones(7,1)*210e9;      % [Pa]
sections.v  = ones(7,1)*0.3;

%% UZLY
nodes.x = [0; 2; 0; 2; 4]*2;
nodes.y = [0; 0; 0; 0; 0]*2;
nodes.z = [0; 0; 2; 2; 0]*2;

%% OKRAJOVÉ PODMÍNKY — vetknuté paty (uzly 1 a 3)
kinematic.x.nodes  = [1; 3];
kinematic.y.nodes  = [1; 3];
kinematic.z.nodes  = [1; 3];
kinematic.rx.nodes = [1; 3];
kinematic.ry.nodes = [1; 3];
kinematic.rz.nodes = [1; 3];

%% PRUTY
beams.nodesHead = [1; 1; 3; 3; 2; 2; 4];
beams.nodesEnd  = [2; 4; 2; 4; 4; 5; 5];
beams.sections  = [1; 2; 3; 4; 5; 6; 7];
beams.angles    = [0; 0; 0; 0; 0; 0; 0];

% idx = [3 5];
idx = [];

beams.nodesHead(idx) = [];
beams.nodesEnd(idx)  = [];
beams.sections(idx)  = [];
beams.angles(idx)    = [];

%% REFERENCE LOAD — 1 N axial compression at the top node
% --------------------------------------------------------------------------
F_ref = -150e3;   % [N]  negative = compression along +z

loads.x.nodes  = [];   loads.x.value  = [];
loads.y.nodes  = [];   loads.y.value  = [];
loads.z.nodes  = [5];  loads.z.value  = [F_ref];
loads.rx.nodes = [];   loads.rx.value = [];
loads.ry.nodes = [];   loads.ry.value = [];
loads.rz.nodes = [];   loads.rz.value = [];

plotStructureFn(nodes, beams, loads, kinematic) 

ndisc = 8;

%% STABILITY ANALYSIS
% --------------------------------------------------------------------------
Results = stabilitySolverFn(sections, nodes, ndisc, kinematic, beams, loads, "mc-guire", 1e-9);

posId = find(Results.values > 0);
posVals = Results.values(posId);

lambda1 = posVals(1);   % smallest positive critical load multiplier
lambda2 = posVals(2);

fprintf('\n');
fprintf('=== Pinned-Pinned Column — Linear Buckling Results ===\n\n');
fprintf('  Reference load       : F_ref = %.2f N  (axial compression)\n', abs(F_ref));
fprintf('\n');
fprintf('  Critical load       : F_crit = %.2f N  (axial compression)\n', abs(lambda1));

plotModeShapeFn(nodes, beams, kinematic, Results, posId(1));