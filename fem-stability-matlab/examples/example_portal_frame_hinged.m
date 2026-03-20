%% example_portal_frame_hinged.m
% ==========================================================================
%  EXAMPLE 3 — Portálový rám s nesymetrickým kloubem průvlaku
% ==========================================================================
%
% Dva vetknuté sloupy (pevná pata i hlava), spojené vodorovným průvlakem.
% Průvlak je připojen KLOUBOVĚ na levém konci a RÁMOVĚ na pravém.
% Sloupy jsou zatíženy tlakem F_ref = 1 N.
%
%  Geometrie (pohled ze strany, rovina XZ):
%
%    2 o====== prut 3 (průvlak) ======| 3
%      ↑ KLOUB (releases(3,1)=true)   ↑ RÁMOVÝ (releases(3,2)=false)
%      |                              |
%   prut 1 (levý sloup)       prut 2 (pravý sloup)
%      |                              |
%    1 ▓▓▓                         ▓▓▓ 4
%    [vetknutí]                 [vetknutí]
%      ↑ F=1N                     ↑ F=1N
%
%  Kloub je VNITŘNÍ — na hlavě levého sloupu (uzel 2).
%  Levý sloup: rámový na obou koncích (moment se přenáší).
%  Průvlak: nepřenáší moment na levý sloup (kloub), ale přenáší na pravý (rám).
%
%  Uzly:
%    1 = (0, 0, 0)  — pata levého sloupu  (vetknutí)
%    2 = (0, 0, H)  — hlava levého sloupu / levý konec průvlaku
%    3 = (B, 0, H)  — hlava pravého sloupu / pravý konec průvlaku
%    4 = (B, 0, 0)  — pata pravého sloupu (vetknutí)
%
% SPUŠTĚNÍ:
%   addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'))
%   example_portal_frame_hinged
%
% ==========================================================================

clear; close all; clc;
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

%% PRŮŘEZOVÉ VLASTNOSTI — HEB 160, ocel
% --------------------------------------------------------------------------
sections.A  = 54.25e-4;   % [m²]
sections.Iy = 2492e-8;    % [m⁴]  silnější osa
sections.Iz = 889.2e-8;   % [m⁴]  slabší osa
sections.Ix = 31.24e-8;   % [m⁴]  torzní moment
sections.E  = 210e9;      % [Pa]
sections.v  = 0.3;

H = 4;   % [m]  výška sloupu
B = 6;   % [m]  rozpětí průvlaku

%% UZLY
% --------------------------------------------------------------------------
nodes.x = [0; 0; B; B];
nodes.y = [0; 0; 0; 0];
nodes.z = [0; H; H; 0];

%% DISKRETIZACE
% --------------------------------------------------------------------------
ndisc = 10;

%% OKRAJOVÉ PODMÍNKY — vetknuté paty, volné hlavy
% --------------------------------------------------------------------------
% Uzly 1 a 4: všechny posuny i pootočení vetknuty (plné vetknutí)
kinematic.x.nodes  = [1; 4];
kinematic.y.nodes  = [1; 4];
kinematic.z.nodes  = [1; 4];
kinematic.rx.nodes = [1; 4];
kinematic.ry.nodes = [1; 4];
kinematic.rz.nodes = [1; 4];

%% PRUTY
% --------------------------------------------------------------------------
%  Prut 1: levý sloup   — uzel 1 (pata) → uzel 2 (hlava)
%  Prut 2: pravý sloup  — uzel 4 (pata) → uzel 3 (hlava)
%  Prut 3: průvlak      — uzel 2 (levý konec) → uzel 3 (pravý konec)

beams.nodesHead = [1; 4; 2];
beams.nodesEnd  = [2; 3; 3];
beams.sections  = [1; 1; 1];
beams.angles    = [0; 0; 0];

%% KLOUBOVÁ SPOJENÍ (beams.releases)
% --------------------------------------------------------------------------
%  releases(i, 1) = kloub na beams.nodesHead(i)
%  releases(i, 2) = kloub na beams.nodesEnd(i)
%
%  Průvlak (prut 3):
%    levý konec  (nodesHead = uzel 2) = KLOUB   → releases(3, 1) = true
%    pravý konec (nodesEnd  = uzel 3) = RÁMOVÝ  → releases(3, 2) = false
%
%  Vizuálně:
%    2 o----- prut 3 (průvlak) -----| 3
%      ↑ kloub                rámový↑
%
%  Sloupy (pruty 1, 2) jsou bez releases — rámově připojeny na obou koncích.

beams.releases = false(3, 2);
beams.releases(3, 1) = true;    % průvlak — levý konec (uzel 2) = KLOUB
% beams.releases(3, 2) = false  % průvlak — pravý konec (uzel 3) = rámový (výchozí)

%% REFERENČNÍ ZATÍŽENÍ — tlak 1 N na hlavy obou sloupů
% --------------------------------------------------------------------------
F_ref = -1;   % [N] záporné = tlak ve směru +z

loads.x.nodes  = [];       loads.x.value  = [];
loads.y.nodes  = [];       loads.y.value  = [];
loads.z.nodes  = [2; 3];   loads.z.value  = [F_ref; F_ref];
loads.rx.nodes = [];       loads.rx.value = [];
loads.ry.nodes = [];       loads.ry.value = [];
loads.rz.nodes = [];       loads.rz.value = [];

%% VIZUALIZACE KONSTRUKCE
% --------------------------------------------------------------------------
figure('Name', 'Portálový rám — schéma', 'Position', [50 50 600 500]);
plotStructureFn(nodes, beams, loads, kinematic);
title({'Portálový rám', 'Průvlak: kloub vlevo ○ — rám vpravo (beams.releases)'});
view(0, 0);

%% ANALÝZA — kloubový průvlak
% --------------------------------------------------------------------------
Results_hinge = stabilitySolverFn(sections, nodes, ndisc, kinematic, beams, loads);
posVals_hinge = sort(Results_hinge.values(Results_hinge.values > 0));

%% SROVNÁNÍ — rámový průvlak (bez releases)
% --------------------------------------------------------------------------
beams_rigid          = beams;
beams_rigid.releases = false(3, 2);   % všechna spojení rámová

Results_rigid = stabilitySolverFn(sections, nodes, ndisc, kinematic, beams_rigid, loads);
posVals_rigid = sort(Results_rigid.values(Results_rigid.values > 0));

%% ANALYTICKÉ SROVNÁNÍ
% --------------------------------------------------------------------------
% Sloup vetknutý-kloubový (efektivní délka L_eff = 2H):
F_cr_pin = pi^2 * sections.E * sections.Iz / (2*H)^2;

% Sloup vetknutý-vetknutý s elastickým tuhou vzpěrou (L_eff ≈ 0.7H):
% Pro rámový průvlak je efektivní délka menší → vyšší kritická síla.
% Přesná hodnota závisí na tuhosti průvlaku, ale pro nekonečně tuhý průvlak:
F_cr_fix = pi^2 * sections.E * sections.Iz / (0.7*H)^2;

%% VÝPIS VÝSLEDKŮ
% --------------------------------------------------------------------------
fprintf('\n');
fprintf('=== Portálový rám — vliv kloubového průvlaku na kritickou sílu ===\n\n');
fprintf('  Geometrie : H = %.1f m, B = %.1f m, průřez HEB 160\n', H, B);
fprintf('  F_ref     = %.0f N (tlak, oba sloupy)\n\n', abs(F_ref));

fprintf('  %-30s  %10s  %10s\n', '', 'lambda_1', 'F_cr,1 [kN]');
fprintf('  %-30s  %10.1f  %10.2f\n', 'Kloubový průvlak (releases):', ...
        posVals_hinge(1), posVals_hinge(1)*abs(F_ref)/1e3);
fprintf('  %-30s  %10.1f  %10.2f\n', 'Rámový průvlak (bez releases):', ...
        posVals_rigid(1), posVals_rigid(1)*abs(F_ref)/1e3);
fprintf('\n');
fprintf('  Analytické reference (jeden sloup, slabší osa Iz):\n');
fprintf('    Vetknutý-kloubový (L_eff=2H): F_cr = %.2f kN\n', F_cr_pin/1e3);
fprintf('    Vetknutý-kloubový (L_eff=0.7H): F_cr = %.2f kN  (jen orientační)\n\n', F_cr_fix/1e3);

fprintf('  Rámový průvlak je %.2f× tužší než kloubový.\n\n', ...
        posVals_rigid(1) / posVals_hinge(1));

%% GRAF
% --------------------------------------------------------------------------
figure('Name', 'Srovnání kloubový vs. rámový průvlak', 'Position', [700 50 600 400]);
n = min(5, min(length(posVals_hinge), length(posVals_rigid)));
bar([posVals_hinge(1:n), posVals_rigid(1:n)] * abs(F_ref) / 1e3);
set(gca, 'XTickLabel', arrayfun(@(i) sprintf('Mód %d', i), 1:n, 'UniformOutput', false));
ylabel('F_{cr}  [kN]');
title({'Portálový rám — kritické síly', ...
       sprintf('H = %.0fm, B = %.0fm, HEB 160', H, B)});
legend('Průvlak: kloub vlevo / rám vpravo', 'Průvlak: plný rám (bez releases)', 'Location', 'northwest');
grid on;
