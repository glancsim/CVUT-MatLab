%% example_portal_frame_hinged.m
% ==========================================================================
%  Portálový rám — lineární analýza s kloubovým spojem průvlaku
% ==========================================================================
%
%  Geometrie (rovina XZ):
%
%    Fx=10kN →  2 o====== průvlak (kloub vlevo) =====| 3
%               |                                     |
%            sloup 1                              sloup 2
%               |                                     |
%             1 ▓▓▓                              ▓▓▓ 4   (vetknutí)
%
%  Uzly:   1=(0,0,0)  2=(0,0,4)  3=(6,0,4)  4=(6,0,0)   [m]
%  Průřez: HEB 160, ocel
%
%  Kloub: průvlak (prut 3) je kloubově spojen s uzlem 2 (levá hlava).
%         → průvlak nepřenáší ohybový moment do levého sloupu.
%         Pravý konec průvlaku (uzel 3) je připojen RÁMOVĚ.
%
%  Výstup: vnitřní síly na koncích každého prutu v lokálních souřadnicích.
%          Lokální osa x = podél prutu (od nodesHead k nodesEnd).
%          Složky: N [N], Vy [N], Vz [N], Mx [N·m], My [N·m], Mz [N·m]
%
% ==========================================================================

clear; close all; clc;
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

%% PRŮŘEZ — HEB 160, ocel
sections.A  = 54.25e-4;   % [m²]
sections.Iy = 2492e-8;    % [m⁴]
sections.Iz = 889.2e-8;   % [m⁴]
sections.Ix = 31.24e-8;   % [m⁴]
sections.E  = 210e9;      % [Pa]
sections.v  = 0.3;

H = 4;   % [m]  výška sloupu
B = 6;   % [m]  délka průvlaku

%% UZLY
nodes.x = [0; 0; B; B];
nodes.y = [0; 0; 0; 0];
nodes.z = [0; H; H; 0];

%% OKRAJOVÉ PODMÍNKY — vetknuté paty (uzly 1 a 4)
kinematic.x.nodes  = [1; 4];
kinematic.y.nodes  = [1; 4];
kinematic.z.nodes  = [1; 4];
kinematic.rx.nodes = [1; 4];
kinematic.ry.nodes = [1; 4];
kinematic.rz.nodes = [1; 4];

%% PRUTY
%  Prut 1: levý sloup   — uzel 1 → uzel 2
%  Prut 2: pravý sloup  — uzel 4 → uzel 3
%  Prut 3: průvlak      — uzel 2 → uzel 3
beams.nodesHead = [1; 4; 2];
beams.nodesEnd  = [2; 3; 3];
beams.sections  = [1; 1; 1];
beams.angles    = [0; 0; 0];

%% KLOUBOVÉ SPOJENÍ
%  releases(i,1) = kloub na nodesHead(i)
%  releases(i,2) = kloub na nodesEnd(i)
%
%  Průvlak (prut 3): kloub na levém konci (nodesHead = uzel 2)
beams.releases = false(3, 2);
beams.releases(3, 1) = true;   % průvlak — levý konec = kloub

%% ZATÍŽENÍ — vodorovná síla 10 kN v uzlu 2
loads.x.nodes  = [2];      loads.x.value  = [10e3];   % [N]
loads.y.nodes  = [];       loads.y.value  = [];
loads.z.nodes  = [];       loads.z.value  = [];
loads.rx.nodes = [];       loads.rx.value = [];
loads.ry.nodes = [];       loads.ry.value = [];
loads.rz.nodes = [];       loads.rz.value = [];

%% VIZUALIZACE
plotStructureFn(nodes, beams, loads, kinematic);
title('Portálový rám — kloub na levém konci průvlaku');
view(0, 0);

%% LINEÁRNÍ ANALÝZA
ndisc = 1;   % pro styčníkové zatížení stačí 1 element/prut
[displacements, endForces] = linearSolverFn(sections, nodes, ndisc, kinematic, beams, loads);

%% VÝPIS VNITŘNÍCH SIL NA KONCÍCH PRUTŮ
% endForces.local (12 × nelem), pro ndisc=1: element i = prut i
% Řádky 1–6:  nodesHead (začátek prutu)
% Řádky 7–12: nodesEnd  (konec prutu)
% Pořadí složek: N, Vy, Vz, Mx, My, Mz  (lokální souřadnice prutu)

labels = {'N [N]', 'Vy [N]', 'Vz [N]', 'Mx [N·m]', 'My [N·m]', 'Mz [N·m]'};
beam_names = {'Sloup 1 (uzel 1→2)', 'Sloup 2 (uzel 4→3)', 'Průvlak (uzel 2→3)'};

fprintf('\n');
fprintf('=== Vnitřní síly na koncích prutů (lokální souřadnice) ===\n\n');

for b = 1:3
    F_head = endForces.local(1:6,  b);   % nodesHead
    F_end  = endForces.local(7:12, b);   % nodesEnd
    fprintf('--- %s ---\n', beam_names{b});
    fprintf('  %-12s  %15s  %15s\n', 'Složka', 'nodesHead', 'nodesEnd');
    for k = 1:6
        fprintf('  %-12s  %15.2f  %15.2f\n', labels{k}, F_head(k), F_end(k));
    end
    fprintf('\n');
end

%% VÝPIS POSUNŮ UZLŮ 2 A 3
fprintf('=== Posuny volných uzlů ===\n');
fprintf('(globální souřadnice, pořadí DOFů: ux, uy, uz, rx, ry, rz)\n\n');
% Rekonstrukce plného vektoru posunů (všechny uzly × 6 DOFů)
u_full = zeros(4, 6);
nnodes = 4;
nodes_tmp = nodes;
nodes_tmp.dofs = true(nnodes, 6);
nodes_tmp.dofs(kinematic.x.nodes,  1) = false;
nodes_tmp.dofs(kinematic.y.nodes,  2) = false;
nodes_tmp.dofs(kinematic.z.nodes,  3) = false;
nodes_tmp.dofs(kinematic.rx.nodes, 4) = false;
nodes_tmp.dofs(kinematic.ry.nodes, 5) = false;
nodes_tmp.dofs(kinematic.rz.nodes, 6) = false;
code = 0;
for nd = 1:nnodes
    for dof = 1:6
        if nodes_tmp.dofs(nd, dof)
            code = code + 1;
            u_full(nd, dof) = displacements.global(code);
        end
    end
end
dof_labels = {'ux [m]','uy [m]','uz [m]','rx [rad]','ry [rad]','rz [rad]'};
fprintf('  %-8s', '');
for k = 1:6, fprintf('  %12s', dof_labels{k}); end
fprintf('\n');
for nd = 2:3
    fprintf('  Uzel %d  ', nd);
    for k = 1:6, fprintf('  %12.6g', u_full(nd,k)); end
    fprintf('\n');
end
fprintf('\n');
