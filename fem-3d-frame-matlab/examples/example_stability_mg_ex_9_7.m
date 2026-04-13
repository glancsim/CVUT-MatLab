% clear; close all; clc;
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

%% PRŮŘEZ — Trubka, ocel

sections.A  = 9.3482*1e-2*0.0006452;           % Plocha [m²]
sections.Iy = 6.9542*1e-4*4.1623*1e-7;         % Moment setrvačnosti k ose y [m⁴]
sections.Iz = sections.Iy;        % Moment setrvačnosti k ose z [m⁴]
sections.Ix = sections.Iy + sections.Iz;         % Polární moment (= Iy + Iz) [m⁴]
sections.E  = 29000*6894757;      % [Pa]
sections.v  = 0.3;

%% UZLY
pole = 20*0.0254;
nodes.x = [0*pole; 1*pole; 2*pole; 3*pole; 0*pole; 1*pole; 2*pole; 3*pole];
nodes.y = [0; 0; 0; 0; 0; 0; 0; 0];
nodes.z = [0; 0; 0; 0; pole; pole; pole; pole];

%% OKRAJOVÉ PODMÍNKY — vetknuté paty (uzly 1 a 4)
kinematic.x.nodes  = [1; 5];
kinematic.y.nodes  = [1;2;3;4;5;6;7;8];
kinematic.z.nodes  = [5];
kinematic.rx.nodes = [1; 5];
kinematic.ry.nodes = [];
kinematic.rz.nodes = [1;2;3;4;5;6;7;8];

%% PRUTY
beams.nodesHead = [ 1; 2; 3;... %spodni pas
                    1; 2; 3; 4;... %svislice
                    1; 6; 3;... %diagonaly
                    5; 6; 7]; %horni pas
beams.nodesEnd  = [ 2; 3; 4;... %spodni pas
                    5; 6; 7; 8;... %svislice
                    6; 3; 8;... %diagonaly
                    6; 7; 8]; %horni pas
beams.sections  = ones(13,1);
beams.angles    = zeros(13,1);

%% REFERENCE LOAD — 1 N axial compression at the top node
% --------------------------------------------------------------------------
F_ref = -1;   % [N]  negative = compression along +z
alpha = 0.0;

loads.x.nodes  = [4;8];   loads.x.value  = [3*F_ref;-3*F_ref];
loads.y.nodes  = [];   loads.y.value  = [];
loads.z.nodes  = [4];  loads.z.value  = [F_ref];
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
lambda1 = posVals(1)*0.225;   % smallest positive critical load multiplier
lambda2 = posVals(2)*0.225;

fprintf('\n');
fprintf('=== McGuire: Matrix structural analysis - Example 9.7 ===\n\n');
fprintf('  Reference critical load   : F_ref = 210 lbs\n');
fprintf('\n');
fprintf('  Critical load             : F_crit = %.2f lbs\n', abs(lambda1));