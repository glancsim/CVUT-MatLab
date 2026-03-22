% test_input.m — Stability test: portálový rám s jedním kloubem na průvlaku
%
% Geometrie (rovina XZ):
%   2 o=====[kloub]====== průvlak ======o 3
%     |                                 |
%  sloup 1                           sloup 2
%     |                                 |
%   1 ▓▓▓                           ▓▓▓ 4    (vetknutí)
%
% Uzly: 1=(0,0,0)  2=(0,0,3)  3=(5,0,3)  4=(5,0,0)  [m]
% Beamy: sloup 1→2, sloup 4→3, průvlak 2→3
% Kloub: beams.releases(3,1)=true  — levý konec průvlaku (uzel 2)
% Zatížení: -1 N svislé (z) v uzlech 2 a 3
% Ověřuje: beams.releases single-end, stability analysis

%% PRŮŘEZY
sections.id = [10; 10; 10];   % 3× profil id=10 ze sectionsSet.mat

%% UZLY
nodes.x = [0.0; 0.0; 5.0; 5.0];
nodes.y = [0.0; 0.0; 0.0; 0.0];
nodes.z = [0.0; 3.0; 3.0; 0.0];

%% DISKRETIZACE
ndisc = 10;

%% PODPORY — vetknuté paty (uzly 1 a 4)
kinematic.x.nodes  = [1; 4];
kinematic.y.nodes  = [1; 4];
kinematic.z.nodes  = [1; 4];
kinematic.rx.nodes = [1; 4];
kinematic.ry.nodes = [1; 4];
kinematic.rz.nodes = [1; 4];

%% PRUTY
beams.nodesHead = [1; 4; 2];
beams.nodesEnd  = [2; 3; 3];
beams.sections  = [1; 1; 1];
beams.angles    = [0; 0; 0];

%% KLOUBY — průvlak kloubově připojen k levému sloupu
beams.releases = false(3, 2);
beams.releases(3, 1) = true;   % průvlak — kloub na hlavovém konci (uzel 2)

%% ZATÍŽENÍ — svislá tlaková síla 1 N v uzlech 2 a 3
loads.x.nodes  = [];   loads.x.value  = [];
loads.y.nodes  = [];   loads.y.value  = [];
loads.z.nodes  = [2; 3];  loads.z.value = [-1; -1];
loads.rx.nodes = [];   loads.rx.value = [];
loads.ry.nodes = [];   loads.ry.value = [];
loads.rz.nodes = [];   loads.rz.value = [];
