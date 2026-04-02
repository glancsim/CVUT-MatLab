% example_truss_hall_30m.m
%
% Posudek příhradového sedlového vazníku průmyslové haly dle EN 1993-1-1.
%
%   Geometrie (dle Jandera — OK 01, kap. 1.4):
%     Rozpětí:         L = 30 m
%     Sklon střechy:   5 %  (→ max výška uprostřed = 3.25 m)
%     Výška v uložení: h = 2.5 m
%     Vzdálenost vazníků: d = 6 m
%     Rozteč vaznic:   a = 3 m  →  10 polí
%     Topologie:       Pratt (diagonály v tahu)
%
%   Průřezy (trubkový CHS vazník, ocel S355):
%     Horní pás:   TR 127×4
%     Dolní pás:   TR 108×6.3
%     Výplň:       TR 76.1×3.2
%
%   Zatížení (charakteristické hodnoty):
%     Střešní plášť: g_k = 0.35 kN/m²
%     Sníh:          s_k = 0.70 kN/m²
%     Sání větru:    w_k = 0.50 kN/m² (kladné = nahoru)
%
%   Kombinace (EN 1990):
%     Kombo 1: 1.35·G + 1.5·S   → max tlak v horním pásu
%     Kombo 2: 1.0·G_min + 1.5·W → uplift, možný tlak v dolním pásu
%
% (c) S. Glanc, 2026

clear; close all;

root   = fileparts(fileparts(mfilename('fullpath')));   % en-truss-design-matlab/
srcDir = fullfile(root, 'src');
femDir = fullfile(root, '..', 'fem-2d-truss-matlab', 'src');
addpath(srcDir);
addpath(femDir);

%% ── Průřezy (zadáme přímo průřezovými charakteristikami) ──────────────
%
%  Skupina 1 = horní pás  (TR 127×4)
%  Skupina 2 = dolní pás  (TR 108×6.3)
%  Skupina 3 = výplňové pruty (TR 76.1×3.2)
%
% Vzorce pro CHS:
%   A = pi/4 * (D^2 - d_i^2),   d_i = D - 2*t
%   I = pi/64 * (D^4 - d_i^4)
%   i = sqrt(I/A)

% --- TR 108×5 (horní pás) ---
D1 = 0.108; t1 = 0.005; di = D1 - 2*t1;
A1 = pi/4 * (D1^2 - di^2);          % m²
I1 = pi/64 * (D1^4 - di^4);         % m⁴
i1 = sqrt(I1/A1);                    % m

% --- TR 159×5.0 (dolní pás) ---
D2 = 0.159; t2 = 0.0050; di = D2 - 2*t2;
A2 = pi/4 * (D2^2 - di^2);
I2 = pi/64 * (D2^4 - di^4);
i2 = sqrt(I2/A2);

% --- TR 82.5×3.6 (výplňové pruty) ---
D3 = 0.0820; t3 = 0.0036; di = D3 - 2*t3;
A3 = pi/4 * (D3^2 - di^2);
I3 = pi/64 * (D3^4 - di^4);
i3 = sqrt(I3/A3);

fprintf('Průřezové charakteristiky:\n');
fprintf('  TR 127×4:    A = %.2f cm², i = %.1f mm,  D/t = %.1f\n', A1*1e4, i1*1e3, D1/t1);
fprintf('  TR 108×6.3:  A = %.2f cm², i = %.1f mm,  D/t = %.1f\n', A2*1e4, i2*1e3, D2/t2);
fprintf('  TR 76.1×3.2: A = %.2f cm², i = %.1f mm,  D/t = %.1f\n', A3*1e4, i3*1e3, D3/t3);
fprintf('  Límit třídy 1 (S355): D/t ≤ %.1f\n', 50*(235/355));

sections.A        = [A1; A2; A3];           % [m²]
sections.E        = [210e9; 210e9; 210e9];  % [Pa]
sections.I        = [I1; I2; I3];           % [m⁴]
sections.i_radius = [i1; i2; i3];           % [m]
sections.curve    = {'a'; 'a'; 'a'};         % horně válcované CHS → křivka a
sections.D        = [D1; D2; D3];           % [m] vnější průměr
sections.t        = [t1; t2; t3];           % [m] tloušťka stěny

%% ── Parametry haly ────────────────────────────────────────────────────
params.span            = 24;      % [m]
params.slope           = 0.05;    % [-]  5% sklon
params.purlin_spacing  = 3;       % [m]  rozteč vaznic
params.h_support       = 1.8;     % [m]  výška v uložení
params.truss_spacing   = 6.6;       % [m]  vzdálenost vazníků
params.f_y             = 355e6;   % [Pa] S355
params.E               = 210e9;   % [Pa]
params.g_roof          = 0.23;    % [kN/m²] plášť
params.g_purlins       = 0.09;    % [kN/m] vaznice  
params.s_k             = 0.80;    % [kN/m²] sníh
params.w_suction       = 0.48;    % [kN/m²] sání (>0 = nahoru)
params.sections        = sections;
params.topology        = 'warren_inverted'; 
params.warren_verticals = true

%% ── Generování geometrie ──────────────────────────────────────────────
[nodes, members, sections, kinematic, loadParams] = trussHallInputFn(params);
nmembers = numel(members.nodesHead);

%% ── Vizualizace geometrie ─────────────────────────────────────────────
combos = loadCombinationsFn(loadParams);

figure('Name', 'Geometrie vazníku — Kombo 1');
plotTrussFn(nodes, members, combos{1}.loads, kinematic, 'Labels', true)
title(sprintf('Příhradový vazník %g m — %s', params.span, combos{1}.description));
axis equal; grid on; xlabel('x [m]'); ylabel('z [m]');

figure('Name', 'Geometrie vazníku — Kombo 2');
plotTrussFn(nodes, members, combos{2}.loads, kinematic, 'Labels', true)
title(sprintf('Příhradový vazník %g m — %s', params.span, combos{2}.description));
axis equal; grid on; xlabel('x [m]'); ylabel('z [m]');

%% ── FEM + Posudek dle EN 1993-1-1 ─────────────────────────────────────
results = designCheckFn(nodes, members, sections, kinematic, loadParams);

%% ── Grafické znázornění vnitřních sil (Kombo 1) ───────────────────────
N1 = results.N_Ed(:, 1);   % [kN], Kombo 1

figure('Name', 'Vnitřní síly — Kombo 1');
hold on; axis equal; grid on;
xlabel('x [m]'); ylabel('z [m]');
title(sprintf('Osové síly N [kN] — %s', combos{1}.description));

Nmax = max(abs(N1)) + eps;
for p = 1:nmembers
    h_n = members.nodesHead(p);
    e_n = members.nodesEnd(p);
    t = N1(p) / Nmax;
    if t >= 0
        col = [1-t, 1-t, 1];   % modrá = tah
    else
        col = [1, 1+t, 1+t];   % červená = tlak
    end
    lw = 1 + 3*abs(t);
    plot([nodes.x(h_n), nodes.x(e_n)], [nodes.z(h_n), nodes.z(e_n)], ...
         '-', 'Color', col, 'LineWidth', lw);
end
plot(nodes.x, nodes.z, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
text(0, -1.0, sprintf('Modrá = tah (max %.0f kN)', max(N1)), ...
     'Color', [0 0 0.8], 'FontSize', 9);
text(0, -1.5, sprintf('Červená = tlak (min %.0f kN)', min(N1)), ...
     'Color', [0.8 0 0], 'FontSize', 9);
hold off;

%% ── Sloupcový graf využití ─────────────────────────────────────────────
figure('Name', 'Využití průřezů — obálka');
bar(results.util_max, 'FaceColor', [0.3 0.6 1]);
hold on;
yline(1.0, 'r--', 'LineWidth', 1.5, 'Label', 'Limit 1.0');
xlabel('Číslo prutu'); ylabel('Využití [-]');
title('Posudek EN 1993-1-1 — obálka využití přes kombinace');
grid on; ylim([0, max(1.1, max(results.util_max)*1.1)]);
hold off;

fprintf('\nHotovo. Výsledek posudku: %s\n', results.status);

%% ── HTML report ───────────────────────────────────────────────────────
reportFile = fullfile(fileparts(mfilename('fullpath')), 'posudek_vaznik_30m.html');
reportFn(params, nodes, members, sections, loadParams, results, reportFile);
fprintf('Report: %s\n', reportFile);
