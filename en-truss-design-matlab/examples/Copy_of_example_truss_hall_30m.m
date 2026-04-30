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

%% ── Průřezy (dle referenčního návrhu Jandera — OK 01) ─────────────────
%
%  Vstupní skupiny (5 profilů):
%    1 = horní pás           H   (TR 108×5)
%    2 = dolní pás           S   (TR 159×5)
%    3 = vnější diagonály    D₁,D₂  (TR 82.5×3.6)
%    4 = vnitřní diagonály   D₃,D₄  (TR 44.5×3.2)
%    5 = svislice            V₁..Vₙ (TR 38×3.2)
%
%  params.diag_sections mapuje symetrické skupiny (zvenku dovnitř)
%  na vstupní průřezy: [3 3 4 4] → D₁,D₂=sec3, D₃,D₄=sec4
%
% Vzorce pro CHS:
%   A = pi/4 * (D^2 - d_i^2),   d_i = D - 2*t
%   I = pi/64 * (D^4 - d_i^4)
%   i = sqrt(I/A)

CHS = @(D, t) struct( ...
    'D', D, 't', t, ...
    'A', pi/4*(D^2 - (D-2*t)^2), ...
    'I', pi/64*(D^4 - (D-2*t)^4), ...
    'i', sqrt( (pi/64*(D^4-(D-2*t)^4)) / (pi/4*(D^2-(D-2*t)^2)) ));

p1 = CHS(0.108,  0.005);    % TR 108×5     — horní pás
p2 = CHS(0.159,  0.005);    % TR 159×5     — dolní pás
p3 = CHS(0.0825, 0.0040);   % TR 82.5×3.6  — vnější diagonály (D₁,D₂)
p4 = CHS(0.0445, 0.0032);   % TR 44.5×3.2  — vnitřní diagonály (D₃,D₄)
p5 = CHS(0.038,  0.0040);   % TR 38×3.2    — svislice

profiles = [p1 p2 p3 p4 p5];
nProf = numel(profiles);

fprintf('Průřezové charakteristiky:\n');
labels = {'TR 108x5  (H)', 'TR 159x5  (S)', 'TR 82.5x3.6 (D1,D2)', ...
          'TR 44.5x3.2 (D3,D4)', 'TR 38x3.2 (V)'};
for k = 1:nProf
    fprintf('  %-22s A = %.2f cm2, i = %.1f mm, D/t = %.1f\n', ...
        labels{k}, profiles(k).A*1e4, profiles(k).i*1e3, profiles(k).D/profiles(k).t);
end
fprintf('  Limit tridy 1 (S355): D/t <= %.1f\n', 50*(235/355));

E_steel = 210e9;
sections.A        = [profiles.A]';
sections.E        = E_steel * ones(nProf, 1);
sections.I        = [profiles.I]';
sections.i_radius = [profiles.i]';
sections.curve    = repmat({'a'}, nProf, 1);    % CHS → krivka a
sections.D        = [profiles.D]';
sections.t        = [profiles.t]';

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
params.s_k             = 1.0;    % [kN/m²] sníh
params.w_suction       = 0.48;    % [kN/m²] sání (>0 = nahoru)
params.sections        = sections;
params.topology        = 'warren_inverted';
params.warren_verticals = true;
params.diag_sections   = [3 3 4 4];        % D₁,D₂ → sec 3; D₃,D₄ → sec 4
params.vert_sections   = 5;                % všechny svislice → sec 5 (skalár = broadcast)
params.support         = 'top';            % podpora v horním pásu (vazník na sloupech)

%% ── Generování geometrie ──────────────────────────────────────────────
[nodes, members, sections, kinematic, loadParams] = trussHallInputFn(params);
nmembers = numel(members.nodesHead);

% Přehled symetrických skupin
sg = loadParams.sectionGroups;
fprintf('\nSymetrické skupiny průřezů (%d celkem):\n', sg.nGroups);
fprintf('  sec 1      = horní pás    (TR %.0f×%.1f)\n', sections.D(1)*1e3, sections.t(1)*1e3);
fprintf('  sec 2      = dolní pás    (TR %.0f×%.1f)\n', sections.D(2)*1e3, sections.t(2)*1e3);
for k = 1:sg.nDiag
    idx = sg.diagIdx(k);
    fprintf('  sec %2d     = diagonála %d  (TR %.0f×%.1f)\n', idx, k, sections.D(idx)*1e3, sections.t(idx)*1e3);
end
for k = 1:sg.nVert
    idx = sg.vertIdx(k);
    fprintf('  sec %2d     = svislice %d   (TR %.0f×%.1f)\n', idx, k, sections.D(idx)*1e3, sections.t(idx)*1e3);
end

%% ── Vizualizace geometrie ─────────────────────────────────────────────
combos = loadCombinationsFn(loadParams);
stripHtml = @(s) regexprep(s, '<[^>]+>', '');   % strip HTML tags
stripHtml = @(s) strrep(strrep(stripHtml(s), '&middot;', '·'), '&nbsp;', ' ');

plotTrussFn(nodes, members, combos{1}.loads, kinematic, 'Labels', true);
title(sprintf('Příhradový vazník %g m — KZS 1: %s', params.span, stripHtml(combos{1}.description)));

plotTrussFn(nodes, members, combos{4}.loads, kinematic, 'Labels', true);
title(sprintf('Příhradový vazník %g m — KZS 4: %s', params.span, stripHtml(combos{4}.description)));

%% ── FEM + Posudek dle EN 1993-1-1 ─────────────────────────────────────
results = designCheckFn(nodes, members, sections, kinematic, loadParams);

%% ── Grafické znázornění vnitřních sil (Kombo 1) ───────────────────────
N1 = results.N_Ed(:, 1);   % [kN], Kombo 1

figure('Name', 'Vnitřní síly — Kombo 1');
hold on; axis equal; grid on;
xlabel('x [m]'); ylabel('z [m]');
title(sprintf('Osové síly N [kN] — KZS 1: %s', stripHtml(combos{1}.description)));

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
reportFn(params, nodes, members, sections, kinematic, loadParams, results, reportFile);
fprintf('Report: %s\n', reportFile);
