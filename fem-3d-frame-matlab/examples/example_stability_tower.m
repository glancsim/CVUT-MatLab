clear; close all; clc;
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

nbricks = 7;   % počet pater

%% PRŮŘEZY — načtení z databáze sectionsSet.mat
%   Sloupy + příčle: SHS (čtvercové trubky),  RHS id viz sectionsSet.RHS
%   Diagonály:       L-profil (otočený 45°),   L   id viz sectionsSet.L
%
%   Dostupné RHS (id 1–9):
%     1=SHS30/30/2,  2=SHS40/40/2.5,  3=SHS50/50/2.5,  4=SHS50/50/3
%     5=SHS50/50/5,  6=SHS100/100/3,  7=SHS100/100/4,  8=SHS100/100/5
%     9=SHS100/100/6
%   Dostupné L (id 10–63, rovnoramenné úhelníky, 54 typů)
%     10=L20/3, 11=L25/3, 12=L30/3, 14=L35/3, 16=L40/3, ...
% --------------------------------------------------------------------------
id_col   = 4;    % SHS50/50/3.0  — sloupy
id_brace = 3;    % SHS50/50/2.5  — příčle
id_diag  = 19;   % L40/4         — diagonály (otočené 45°)

load(fullfile(fileparts(mfilename('fullpath')), '..', '..', ...
    'Diplomka', 'towerOptSA', 'sectionsSet.mat'));

% Pomocná funkce: vyber řádek z tabulky podle id
get_sec = @(tbl, id) tbl(tbl.id == id, :);

col_row   = get_sec(sectionsSet.RHS, id_col);
brace_row = get_sec(sectionsSet.RHS, id_brace);
diag_row  = get_sec(sectionsSet.L,   id_diag);

fprintf('Sloupy:    %s  (id=%d)\n', col_row.Typ,   id_col);
fprintf('Pricky:    %s  (id=%d)\n', brace_row.Typ, id_brace);
fprintf('Diagonaly: %s  (id=%d, 45 deg)\n', diag_row.Typ, id_diag);

% Sestavení 21 průřezů: (patro-1)*3 + [1=sloup, 2=diag, 3=příčel]
nsec = nbricks * 3;
is_col   = (mod((1:nsec)', 3) == 1);
is_diag  = (mod((1:nsec)', 3) == 2);
is_brace = (mod((1:nsec)', 3) == 0);

sections.A  = zeros(nsec, 1);
sections.Iy = zeros(nsec, 1);
sections.Iz = zeros(nsec, 1);
sections.Ix = zeros(nsec, 1);

sections.A(is_col)   = col_row.A;    sections.Iy(is_col)   = col_row.I_y;
sections.Iz(is_col)  = col_row.I_z;  sections.Ix(is_col)   = col_row.I_t;

sections.A(is_diag)  = diag_row.A;   sections.Iy(is_diag)  = diag_row.I_y;
sections.Iz(is_diag) = diag_row.I_z; sections.Ix(is_diag)  = diag_row.I_t;

sections.A(is_brace)  = brace_row.A;   sections.Iy(is_brace)  = brace_row.I_y;
sections.Iz(is_brace) = brace_row.I_z; sections.Ix(is_brace)  = brace_row.I_t;

sections.E = ones(nsec, 1) * 210e9;
sections.v = ones(nsec, 1) * 0.3;

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
angle_pattern = [zeros(4,1); 45*ones(16,1); zeros(4,1)];   % 24×1: sloupy=0°, diag=45°, příčle=0°
beams.angles = zeros(numel(beams.nodesHead), 1);
for i = 1:nbricks
    idx = (i-1)*24 + (1:24);
    beams.angles(idx) = angle_pattern;
end

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