% clear; close all; clc;
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

%% PRŮŘEZ — Trubka, ocel

sections.A  = 3.9100*1e3*1e-6;           % Plocha [m²]
sections.Iy = 3.8910*1e7*1e-12;         % Moment setrvačnosti k ose y [m⁴]
sections.Iz = 2.8360*1e6*1e-12;        % Moment setrvačnosti k ose z [m⁴]
sections.Ix = 1.2950*1e5*1e-12;         % Polární moment (= Iy + Iz) [m⁴]
sections.E  = 210e9;      % [Pa]
sections.v  = 0.3;

%% UZLY
nodes.x = [0; 4; 4; 0; 0; 4; 4; 0];
nodes.y = [0; 0; 4; 4; 0; 0; 4; 4];
nodes.z = [0; 0; 0; 0; 5; 5; 5; 5];

%% OKRAJOVÉ PODMÍNKY — vetknuté paty (uzly 1 a 4)
kinematic.x.nodes  = [1;2;3;4];
kinematic.y.nodes  = [1;2;3;4];
kinematic.z.nodes  = [1;2;3;4];
kinematic.rx.nodes = [];
kinematic.ry.nodes = [];
kinematic.rz.nodes = [];

%% PRUTY
beams.nodesHead = [1; 2; 3; 4; 5; 7; 5; 6];
beams.nodesEnd  = [5; 6; 7; 8; 6; 8; 8; 7];
beams.sections  = [1; 1; 1; 1; 1; 1; 1; 1];
% beams.angles    = [0; 90; 90; 0; 90; 90; 0; 0];
beams.angles    = [90; 0; 90; 0; 90; 0; 0; 0];

%% REFERENCE LOAD — 1 N axial compression at the top node
% --------------------------------------------------------------------------
F_ref = 1000;   % [N]  negative = compression along +z

loads.x.nodes  = [5;6;7;8];   loads.x.value  = [F_ref;F_ref;-F_ref;-F_ref];
loads.y.nodes  = [5;6;7;8];   loads.y.value  = [-F_ref;F_ref;F_ref;-F_ref];
loads.z.nodes  = [5;6;7;8];   loads.z.value  = [-F_ref;-F_ref;-F_ref;-F_ref];
loads.rx.nodes = [];   loads.rx.value = [];
loads.ry.nodes = [];   loads.ry.value = [];
loads.rz.nodes = [];   loads.rz.value = [];

% plotStructureFn(nodes, beams, loads, kinematic) 

ndisc = 2;
%% STABILITY ANALYSIS
% --------------------------------------------------------------------------
Results = stabilitySolverFn(sections, nodes, ndisc, kinematic, beams, loads, "oofem", 1e-9);

% plotModeShapeFn(nodes, beams, kinematic, Results);

posVals = Results.values(Results.values > 0);
lambda1 = posVals(1);   % smallest positive critical load multiplier
lambda2 = posVals(2);

fprintf('\n');
fprintf('===Scia Engineer - Example with 3 rotated beams===\n\n');
fprintf('  Reference critical load 1    : F_ref = 62.68 kN\n');
fprintf('\n');
fprintf('  Critical load                : F_crit = %.2f kN\n', abs(lambda1));
fprintf('\n');
fprintf('  Reference critical load 2    : F_ref = 132.07 kN\n');
fprintf('\n');
fprintf('  Critical load                : F_crit = %.2f kN\n', abs(lambda2));