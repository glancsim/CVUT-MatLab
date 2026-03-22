% test_input.m — Test 12: Torri benchmark
%
% Rovinná rámová konstrukce (Torri) v rovině XZ.
% Klasický benchmark pro lineární analýzu stability.
%
%   Geometrie (x, z):
%     Uzel 1: (0, 0, 0)   — vetknutí (pin: volné rx, ry)
%     Uzel 2: (2, 0, 0)   — volný
%     Uzel 3: (0, 0, 2)   — vetknutí (pin: volné rx, ry)
%     Uzel 4: (2, 0, 2)   — volný
%     Uzel 5: (4, 0, 2)   — místo zatížení
%
%   Pruty:
%     1: 1→2  (dolní příčel, vodorovná)
%     2: 3→4  (horní příčel vlevo, vodorovná)
%     3: 4→5  (horní příčel vpravo, vodorovná)
%     4: 3→2  (diagonála)
%     5: 2→5  (diagonála)
%     6: 2→4  (svislice)
%
%   Podpory (uzly 1, 3): vetknuté posuny + rz; rx, ry volné → 3D pin
%   Zatížení: Fz = -1000 N v uzlu 5
%
% Průřez: trubka Ø80/70 mm, ocel (E=210 GPa)

%% PRŮŘEZ — přímé vlastnosti (bez sectionsSet.mat)
r_o = 0.04;    % vnější poloměr [m]
r_i = 0.035;   % vnitřní poloměr [m]
sections.A  = pi * (r_o^2 - r_i^2);
sections.Iy = pi/4 * (r_o^4 - r_i^4);
sections.Iz = pi/4 * (r_o^4 - r_i^4);
sections.Ix = pi/2 * (r_o^4 - r_i^4);
sections.E  = 210e9;
sections.v  = 0.3;

%% UZLY
nodes.x = [0; 2; 0; 2; 4];
nodes.y = [0; 0; 0; 0; 0];
nodes.z = [0; 0; 2; 2; 2];

%% DISKRETIZACE
ndisc = 16;

%% OKRAJOVÉ PODMÍNKY — 3D pin v uzlech 1 a 3 (volné rx, ry)
kinematic.x.nodes  = [1; 3];
kinematic.y.nodes  = [1; 3];
kinematic.z.nodes  = [1; 3];
kinematic.rx.nodes = [];
kinematic.ry.nodes = [];
kinematic.rz.nodes = [1; 3];

%% PRUTY
beams.nodesHead = [1; 3; 4; 3; 2; 2];
beams.nodesEnd  = [2; 4; 5; 2; 5; 4];
beams.sections  = ones(6, 1);
beams.angles    = zeros(6, 1);

%% REFERENČNÍ ZATÍŽENÍ
loads.x.nodes  = [];   loads.x.value  = [];
loads.y.nodes  = [];   loads.y.value  = [];
loads.z.nodes  = [5];  loads.z.value  = [-1000];
loads.rx.nodes = [];   loads.rx.value = [];
loads.ry.nodes = [];   loads.ry.value = [];
loads.rz.nodes = [];   loads.rz.value = [];
