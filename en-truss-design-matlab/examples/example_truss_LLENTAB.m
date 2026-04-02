% example_truss_LLENTAB.m
%
% Posudek příhradového vazníku LLENTAB dle EN 1993-1-1.
%
%   Geometrie importována z: Truss_export_LLENTAB.xlsx
%     Rozpětí:         L ≈ 23.26 m
%     Max. výška:      h ≈ 2.05 m  (uzel 15, střed vazníku)
%     Výška v uložení: 0.59 m
%     Počet prutů:     55
%     Počet uzlů:      29
%
%   Skupiny průřezů (k doplnění):
%     1 = horní pás   (16 prutů, sedle)
%     2 = dolní pás   (11 prutů, beton)
%     3 = výplň        (28 prutů, diagonály + svislice)
%
%   Podpory: Kloubová (uzel 1) + Pojezdová (uzel 29)
%
% (c) S. Glanc, 2026

clear; close all;

root   = fileparts(fileparts(mfilename('fullpath')));   % en-truss-design-matlab/
srcDir = fullfile(root, 'src');
femDir = fullfile(root, '..', 'fem-2d-truss-matlab', 'src');
addpath(srcDir);
addpath(femDir);

%% ── Průřezy — doplňte průřezové charakteristiky ─────────────────────────
%
%  TODO: nahraďte níže hodnoty za skutečné průřezy ze sortimentu LLENTAB.
%
%  Skupina 1 = horní pás
%  Skupina 2 = dolní pás
%  Skupina 3 = výplňové pruty (diagonály + svislice)
%
%  Vzorce pro CHS:   di = D - 2*t
%    A = pi/4*(D^2 - di^2)
%    I = pi/64*(D^4 - di^4)
%    i = sqrt(I/A)

% --- Skupina 1: horní pás ---
D1 = 0.127;  t1 = 0.004;   % TODO: doplňte skutečné rozměry
di = D1 - 2*t1;
A1 = pi/4*(D1^2 - di^2);  I1 = pi/64*(D1^4 - di^4);  i1 = sqrt(I1/A1);

% --- Skupina 2: dolní pás ---
D2 = 0.108;  t2 = 0.0063;  % TODO: doplňte skutečné rozměry
di = D2 - 2*t2;
A2 = pi/4*(D2^2 - di^2);  I2 = pi/64*(D2^4 - di^4);  i2 = sqrt(I2/A2);

% --- Skupina 3: výplňové pruty ---
D3 = 0.0761; t3 = 0.0032;  % TODO: doplňte skutečné rozměry
di = D3 - 2*t3;
A3 = pi/4*(D3^2 - di^2);  I3 = pi/64*(D3^4 - di^4);  i3 = sqrt(I3/A3);

fprintf('Průřezové charakteristiky:\n');
fprintf('  Skupina 1:  A = %.2f cm², i = %.1f mm,  D/t = %.1f\n', A1*1e4, i1*1e3, D1/t1);
fprintf('  Skupina 2:  A = %.2f cm², i = %.1f mm,  D/t = %.1f\n', A2*1e4, i2*1e3, D2/t2);
fprintf('  Skupina 3:  A = %.2f cm², i = %.1f mm,  D/t = %.1f\n', A3*1e4, i3*1e3, D3/t3);

sections.A        = [A1; A2; A3];           % [m²]
sections.E        = [210e9; 210e9; 210e9];  % [Pa]
sections.I        = [I1; I2; I3];           % [m⁴]
sections.i_radius = [i1; i2; i3];           % [m]
sections.curve    = {'a'; 'a'; 'a'};         % CHS horně válcované → křivka a
sections.D        = [D1; D2; D3];           % [m]
sections.t        = [t1; t2; t3];           % [m]

%% ── Geometrie uzlů — importováno z LLENTAB ───────────────────────────────
nodes.x = [
    0.0000; 0.5900; 1.3500; 2.0900; 2.8500; 3.6000; 4.3500; 5.0900;
    5.8500; 7.3500; 7.3500; 8.8500; 10.0600; 10.0600; 11.6300; 13.2000;
    13.2000; 14.4100; 15.9200; 15.9200; 17.4100; 18.1700; 18.9100; 19.6600;
    20.4100; 21.1700; 21.9100; 22.6700; 23.2600
];
nodes.z = [
    0.5900; 0.0000; 0.7600; 0.0000; 0.9500; 0.0000; 1.1400; 0.0000;
    1.3300; 0.0000; 1.5100; 1.7000; 0.0000; 1.8500; 2.0500; 0.0000;
    1.8500; 1.7000; 0.0000; 1.5100; 1.3300; 0.0000; 1.1400; 0.0000;
    0.9500; 0.0000; 0.7600; 0.0000; 0.5900
];

%% ── Pruty — importováno z LLENTAB ────────────────────────────────────────
%  Skupiny průřezů: 1 = horní pás, 2 = dolní pás, 3 = výplň
members.nodesHead = [
    13; 19; 22; 24; 26; 15; 17; 18;
    20; 21; 23; 25; 16; 27; 16; 18;
    19; 21; 22; 23; 24; 25; 26; 27;
    28; 15; 19; 13;  1; 10;  8;  6;
     4;  2; 14; 12; 11;  9;  7;  5;
    10;  3; 13; 12; 10;  9;  8;  7;
     6;  5;  4;  3;  2;  1; 16
];
members.nodesEnd = [
    16; 22; 24; 26; 28; 17; 18; 20;
    21; 23; 25; 27; 19; 29; 18; 19;
    21; 22; 23; 24; 25; 26; 27; 28;
    29; 16; 20; 14;  2; 13; 10;  8;
     6;  4; 15; 14; 12; 11;  9;  7;
    11;  5; 15; 13; 12; 10;  9;  8;
     7;  6;  5;  4;  3;  3; 17
];
members.sections = [
    2; 2; 2; 2; 2; 1; 1; 1;
    1; 1; 1; 1; 2; 1; 3; 3;
    3; 3; 3; 3; 3; 3; 3; 3;
    3; 3; 3; 3; 3; 2; 2; 2;
    2; 2; 1; 1; 1; 1; 1; 1;
    3; 1; 3; 3; 3; 3; 3; 3;
    3; 3; 3; 3; 3; 1; 3
];
members.nmembers = numel(members.nodesHead);

%% ── Podpory ──────────────────────────────────────────────────────────────
% Uzel  1: (  0.00; 0.59) — kloubová podpora (ux + uz)
% Uzel 29: (23.26; 0.59) — pojezdová (uz)
kinematic.x.nodes = 1;
kinematic.z.nodes = [1; 29];

%% ── Parametry zatížení ───────────────────────────────────────────────────
%  TODO: upravte hodnoty dle projektu

params.span           = 23.26;   % [m]
params.slope          = 0.088;   % [-]  ≈ 2.05/23.26 — ekvivalentní sklon
params.h_support      = 0.59;    % [m]
params.truss_spacing  = 6.0;     % [m]  TODO: vzdálenost vazníků
params.purlin_spacing = 1.45;    % [m]  průměrná rozteč vaznicových uzlů
params.f_y            = 355e6;   % [Pa] S355
params.E              = 210e9;   % [Pa]
params.g_roof         = 0.35;    % [kN/m²] plášť
params.s_k            = 0.70;    % [kN/m²] sníh
params.w_suction      = 0.50;    % [kN/m²] sání (>0 = nahoru)
params.sections       = sections;

%% ── loadParams — ruční sestavení (obchází trussHallInputFn) ─────────────
% Uzly horního pásu (na které se aplikuje zatížení)
top_nodes = [1; 3; 5; 7; 9; 11; 12; 14; 15; 17; 18; 20; 21; 23; 25; 27; 29];

% Tributary délky pro každý uzel horního pásu [m]
% (polovina vzdálenosti k sousedním uzlům podél horního pásu v rovině x)
trib = [
    0.6750; 1.4250; 1.5000; 1.5000; 1.5000; 1.5000; 1.3550; 1.3900;
    1.5700; 1.3900; 1.3600; 1.5000; 1.4950; 1.5000; 1.5000; 1.4250;
    0.6750
];

% Vlastní tíha vazníku (Jandera OK-01, kap. 1.4.4)
L      = params.span;
g_d    = params.g_roof + params.s_k;
g_self = L / 76 * sqrt(g_d * params.truss_spacing);
g_total = params.g_roof + g_self;
g_min   = params.g_roof + 0.5 * g_self;
fprintf('\nVlastní tíha (odhad): g = %.3f kN/m²,  g_min = %.3f kN/m²\n', g_total, g_min);

loadParams.top_nodes       = top_nodes;
loadParams.trib            = trib;
loadParams.truss_spacing   = params.truss_spacing;
loadParams.g_total         = g_total;
loadParams.g_min           = g_min;
loadParams.s_k             = params.s_k;
loadParams.w_suction       = params.w_suction;
loadParams.f_y             = params.f_y;
loadParams.E               = params.E;
loadParams.purlin_spacing  = params.purlin_spacing;
loadParams.bracing_spacing = params.truss_spacing;
loadParams.n_panels        = numel(top_nodes) - 1;
loadParams.sections        = sections;
loadParams.topology        = 'llentab';
loadParams.shape           = 'saddle';

%% ── Vizualizace geometrie ─────────────────────────────────────────────
combos = loadCombinationsFn(loadParams);

figure('Name', 'Geometrie LLENTAB — Kombo 1');
plotTrussFn(nodes, members, combos{1}.loads, kinematic, 'Labels', false);
title(sprintf('Příhradový vazník LLENTAB %.1f m — %s', L, combos{1}.description));
axis equal; grid on; xlabel('x [m]'); ylabel('z [m]');

%% ── FEM + Posudek dle EN 1993-1-1 ─────────────────────────────────────
results = designCheckFn(nodes, members, sections, kinematic, loadParams);

%% ── Grafické znázornění vnitřních sil (Kombo 1) ───────────────────────
N1 = results.N_Ed(:, 1);
nmembers = members.nmembers;

figure('Name', 'Vnitřní síly — Kombo 1');
hold on; axis equal; grid on;
xlabel('x [m]'); ylabel('z [m]');
title(sprintf('Osové síly N [kN] — %s', combos{1}.description));

Nmax = max(abs(N1)) + eps;
for p = 1:nmembers
    h_n = members.nodesHead(p);
    e_n = members.nodesEnd(p);
    t = N1(p) / Nmax;
    col = [1-max(t,0), 1-abs(t), 1+min(t,0)];
    lw = 1 + 3*abs(t);
    plot([nodes.x(h_n), nodes.x(e_n)], [nodes.z(h_n), nodes.z(e_n)], ...
         '-', 'Color', col, 'LineWidth', lw);
end
plot(nodes.x, nodes.z, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
text(0, -0.5, sprintf('Modrá = tah (max %.0f kN)', max(N1)), 'Color', [0 0 0.8], 'FontSize', 9);
text(0, -0.8, sprintf('Červená = tlak (min %.0f kN)', min(N1)), 'Color', [0.8 0 0], 'FontSize', 9);
hold off;

%% ── Sloupcový graf využití ─────────────────────────────────────────────
figure('Name', 'Využití průřezů');
bar(results.util_max, 'FaceColor', [0.3 0.6 1]);
hold on;
yline(1.0, 'r--', 'LineWidth', 1.5, 'Label', 'Limit 1.0');
xlabel('Číslo prutu'); ylabel('Využití [-]');
title('Posudek EN 1993-1-1 — obálka využití');
grid on; ylim([0, max(1.1, max(results.util_max)*1.1)]);

fprintf('\nHotovo. Výsledek: %s\n', results.status);

%% ── HTML report ───────────────────────────────────────────────────────
reportFile = fullfile(fileparts(mfilename('fullpath')), 'posudek_vaznik_LLENTAB.html');
reportFn(params, nodes, members, sections, loadParams, results, reportFile);
fprintf('Report: %s\n', reportFile);
