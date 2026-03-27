clear; close all; clc;
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

nbricks = 7;   % počet pater

%% PRŮŘEZY — 3 skupiny na patro × nbricks pater = nbricks*3 průřezů
%   Index sekce = (patro-1)*3 + typ,  kde typ: 1=sloupy, 2=diagonály, 3=příčle
%
%   Patro 1: sec 1 (sloupy), sec 2 (diagonály), sec 3 (příčle)
%   Patro 2: sec 4 (sloupy), sec 5 (diagonály), sec 6 (příčle)
%   ...
%
%   Uprav r_outer/r_inner per sekci libovolně, např.:
%     r_outer(1:3:end) = 0.05;  r_inner(1:3:end) = 0.044;  % sloupy
%     r_outer(2:3:end) = 0.03;  r_inner(2:3:end) = 0.026;  % diagonály
%     r_outer(3:3:end) = 0.025; r_inner(3:3:end) = 0.022;  % příčle
% --------------------------------------------------------------------------
nsec    = nbricks * 3;
r_outer = 0.04  * ones(nsec, 1);
r_inner = 0.035 * ones(nsec, 1);

sections.A  = pi    .* (r_outer.^2 - r_inner.^2);
sections.Iy = pi/4  .* (r_outer.^4 - r_inner.^4);
sections.Iz = pi/4  .* (r_outer.^4 - r_inner.^4);
sections.Ix = pi/2  .* (r_outer.^4 - r_inner.^4);
sections.E  = ones(nsec, 1) * 210e9;
sections.v  = ones(nsec, 1) * 0.3;

%% UZLY
width = 2.9;
length = 2.9;
height = 3;
topHeight = 20;
nodes.x = [[0;length;length;0];kron(ones(nbricks,1),[length/2;length;length/2;0;0;length;length;0])];                            % x coordinates of nodes
nodes.y = [[0;0;width;width];kron(ones(nbricks,1),[0;width/2;width;width/2;0;0;width;width])];                              % y coordinates of nodes
nodes.z = [0;0;0;0];
for i = 1:nbricks
    nodes.z  = [nodes.z; [height/2;height/2;height/2;height/2;height;height;height;height] + (i-1) .* [height;height;height;height;height;height;height;height]];
end
nodes.z((nbricks)*7+4:(nbricks+1)*7+4) =[topHeight-(topHeight - height*(nbricks-1))/2;topHeight-(topHeight - height*(nbricks-1))/2;topHeight-(topHeight - height*(nbricks-1))/2;topHeight-(topHeight - height*(nbricks-1))/2;topHeight;topHeight;topHeight;topHeight]; % z coordinates of nodes


%% OKRAJOVÉ PODMÍNKY — vetknuté paty (uzly 1 a 4)
kinematic.x.nodes = [1;2;3;4];              % node indices with restricted x-direction displacements
kinematic.y.nodes = [1;2;3;4];              % node indices with restricted y-direction displacements
kinematic.z.nodes = [1;2;3;4];              % node indices with restricted z-direction displacements
kinematic.rx.nodes = [];                    % node indices with restricted x-direction displacements
kinematic.ry.nodes = [];                   % node indices with restricted y-direction displacements
kinematic.rz.nodes = [];                    % node indices with restricted z-direction displacements

%% PRUTY
modulNodes1 = [1;2;3;4; 1;5;2;5;2;6;3;6;3;7;4;7;4;8;1;8; 9;10;11;12  ];   % elements starting nodes
beams.nodesHead = (reshape(kron(modulNodes1', ones(nbricks, 1))', 1, [])' ...
        + repelem((0:nbricks-1)', numel(modulNodes1))*8);
% beams.nodesHead = modulNodes1;
modulNodes2 = [9;10;11;12; 5;10;5;9;6;11;6;10;7;12;7;11;8;9;8;12; 10;11;12;9  ];   % elements ending nodes
beams.nodesEnd = (reshape(kron(modulNodes2', ones(nbricks, 1))', 1, [])' ...
        + repelem((0:nbricks-1)', numel(modulNodes2))*8);
% beams.nodesEnd = modulNodes2;
beams.angles = zeros(numel(beams.nodesHead), 1);

% Průřezy: vzor na jedno patro [4 sloupy | 16 diagonál | 4 příčle]
% Sekce (patro i) = (i-1)*3 + [1, 2, 3]
pattern = [ones(4,1); 2*ones(16,1); 3*ones(4,1)];   % 24×1
beams.sections = zeros(numel(beams.nodesHead), 1);
for i = 1:nbricks
    idx = (i-1)*24 + (1:24);
    beams.sections(idx) = (i-1)*3 + pattern;
end

%% REFERENCE LOAD — 1 N axial compression at the top node
% --------------------------------------------------------------------------
loads.y.nodes = reshape((repmat([1,2], nbricks, 1) + (1:nbricks)'*8).',1,[])';             % node indices with x-direction forces
loads.y.value = ones(nbricks*2,1)*0.25;             % magnitude of the x-direction forces
loads.x.nodes = [1;2;3;4]+(nbricks)*8;             % node indices with y-direction forces
loads.x.value = [-10;-10;-10;-10]*10^3;             % magnitude of the y-direction forces 
loads.z.nodes = [1;2;3;4]+(nbricks)*8;             % node indices with y-direction forces
loads.z.value = [-10;-10;-10;-10]*10^3;             % magnitude of the y-direction forces 

loads.rx.nodes = [];   loads.rx.value = [];
loads.ry.nodes = [];   loads.ry.value = [];
loads.rz.nodes = [];   loads.rz.value = [];

plotStructureFn(nodes, beams, loads, kinematic) 

ndisc = 5;

%% STABILITY ANALYSIS
% --------------------------------------------------------------------------
Results = stabilitySolverFn(sections, nodes, ndisc, kinematic, beams, loads);

plotModeShapeFn(nodes, beams, kinematic, Results);

posVals = Results.values(Results.values > 0);
lambda1 = posVals(1);   % smallest positive critical load multiplier
lambda2 = posVals(2);

fprintf('\n');
fprintf('=== Results ===\n\n');
fprintf('\n');
fprintf('  Critical load       : F_crit = %.2f N  (axial compression)\n', abs(lambda1));