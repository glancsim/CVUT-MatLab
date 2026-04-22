% example_reliability_24m.m
%
% Spolehlivostní analýza příhradového vazníku metodou Monte Carlo (UQLab).
%
% ── OKRAJOVÉ PODMÍNKY PŘÍKLADU ─────────────────────────────────────────
%   Objekt:          zateplená hala (C_t = 1.0 dle ČSN EN 1991-1-3 Tab. D.1)
%   Půdorys:         24 m × 59.4 m  (1 pole × 9 polí á 6.6 m)
%   Vazník:          24 m Warren inverted, sklon 5 %, S355, CHS
%   Střešní plášť:   g_roof = 0.23 kN/m² (char.)
%   Sněhová oblast:  II (ČR)  →  s_k = 1.0 kN/m² (ČSN EN 1991-1-3 NA)
%   Větrná oblast:   II       →  v_b,0 = 25 m/s  (nepoužito: pouze G + S)
%   Kategorie terénu: III     →  C_e,mean = 1.0  (Tab. 5.1)
%   C_t:             1.0      (zateplená střecha, bez tání)
%   Zatížení:        gravitace (G) + sníh (S) — vítr se v reliability nepočítá
%   Systém:          sériový — selhání jednoho prutu = kolaps
%
% Náhodné veličiny dle JRC TR "Reliability background of the Eurocodes" (2024),
% Table 3.7, Annex A + ČSN EN 1991-1-3 ed. 2.
%
% Cílový index spolehlivosti: β_t = 4.1 (JCSS, sériový systém, ocel, sníh, 1 rok)
%
% Prerekvizita: UQLab framework (https://www.uqlab.com/)
%
% (c) S. Glanc, 2026

clear; close all;

%% ── Cesty k modulům ──────────────────────────────────────────────────
root     = fileparts(fileparts(mfilename('fullpath')));  % reliability-truss-matlab/
srcDir   = fullfile(root, 'src');
designDir = fullfile(root, '..', 'en-truss-design-matlab', 'src');
femDir   = fullfile(root, '..', 'fem-2d-truss-matlab', 'src');

addpath(srcDir);
addpath(designDir);
addpath(femDir);

% Inicializace UQLab
uqlab;

%% ── Průřezy (stejné jako example_truss_hall_30m.m) ───────────────────
CHS = @(D, t) struct( ...
    'D', D, 't', t, ...
    'A', pi/4*(D^2 - (D-2*t)^2), ...
    'I', pi/64*(D^4 - (D-2*t)^4), ...
    'i', sqrt( (pi/64*(D^4-(D-2*t)^4)) / (pi/4*(D^2-(D-2*t)^2)) ));

p1 = CHS(0.108,  0.005);    % TR 108×5     — horní pás
p2 = CHS(0.159,  0.005);    % TR 159×5     — dolní pás
p3 = CHS(0.0825, 0.0036);   % TR 82.5×3.6  — vnější diagonály
p4 = CHS(0.0445, 0.0032);   % TR 44.5×3.2  — vnitřní diagonály
p5 = CHS(0.038,  0.0032);   % TR 38×3.2    — svislice

profiles = [p1 p2 p3 p4 p5];
nProf = numel(profiles);

E_steel = 210e9;
sections.A        = [profiles.A]';
sections.E        = E_steel * ones(nProf, 1);
sections.I        = [profiles.I]';
sections.i_radius = [profiles.i]';
sections.curve    = repmat({'a'}, nProf, 1);    % CHS hot-finished → křivka a
sections.D        = [profiles.D]';
sections.t        = [profiles.t]';

%% ── Parametry haly ────────────────────────────────────────────────────
% Půdorys 24 × 59.4 m, 9 polí á 6.6 m. Vazníky po 6.6 m → truss_spacing.
params.span            = 24;      % [m] rozpětí vazníku (1 pole)
params.slope           = 0.05;    % [-] 5 % sklon střechy
params.purlin_spacing  = 3;       % [m] rozteč vaznic
params.h_support       = 1.8;     % [m] výška v uložení
params.truss_spacing   = 6.6;     % [m] vzdálenost vazníků (podélné pole)
params.f_y             = 355e6;   % [Pa] S355
params.E               = 210e9;   % [Pa]
params.g_roof          = 0.23;    % [kN/m²] střešní plášť (char.)
params.g_purlins       = 0.09;    % [kN/m] vaznice
params.s_k             = 1.0;     % [kN/m²] sníh char. (II. sněhová oblast ČR)
params.w_suction       = 0.48;    % [kN/m²] sání (II. větrná obl., kat. terénu III — nepoužito v reliabilitě)
params.sections        = sections;
params.topology        = 'warren_inverted';
params.warren_verticals = true;
params.diag_sections   = [3 3 4 4];
params.vert_sections   = 5;
params.support         = 'top';

%% ── Generování geometrie ──────────────────────────────────────────────
[nodes, members, sections, kinematic, loadParams] = trussHallInputFn(params);
nmembers = numel(members.nodesHead);

% Vykreslení bez zatížení — prázdné loads:
emptyLoads.x.nodes = [];  emptyLoads.x.value = [];
emptyLoads.z.nodes = [];  emptyLoads.z.value = [];

% plotTrussFn(nodes, members, emptyLoads, kinematic, 'Labels', true);

plotTrussTopologyFn(nodes, members, kinematic, 'Labels', true)
% title('Truss 24 m — Warren inverted');

fprintf('\nGeometrie: %d prutů, %d uzlů, %d průřezových skupin\n', ...
    nmembers, numel(nodes.x), loadParams.sectionGroups.nGroups);

%% ── Deterministický posudek (pro srovnání) ────────────────────────────
fprintf('\n--- Deterministický posudek EN 1993-1-1 ---\n');
detResults = designCheckFn(nodes, members, sections, kinematic, loadParams);
fprintf('  Max. využití: %.3f (prut %d)\n', max(detResults.util_max), ...
    find(detResults.util_max == max(detResults.util_max), 1));

%% ── Spolehlivostní posudek ────────────────────────
fprintf('\n====== FÁZE 3: Plný běh ======\n');
mcOpts.nSamples  = 1e7;
mcOpts.batchSize = 1e5;
mcOpts.method    = 'MCS';             % 'MCS' / 'Subset' / 'IS'

% Sníh na zemi — skutečná data stanice (varianta B: Q1 přímo v kN/m²):
%   Stanice: Letiště Leoše Janáčka Ostrava (Mošnov), 1961–2022 (n = 61 let)
%   Roční maxima: μ = 0.31 kN/m², COV = 0.61, šikmost = 1.09 ≈ Gumbel (1.14)
mcOpts.rvOpts.Q1_mean = 0.31;   % [kN/m²]
mcOpts.rvOpts.Q1_cov  = 0.61;

% μ₁ a Ce jsou deterministické dle prEN 1991-1-3 — jejich variabilita je
% zahrnuta v θ_Q2 (JRC TR 2024 Annex A, Tab. A.8):
%   μ₁ = 0.80 — plochá střecha, sklon 5 % ≤ 30° (Tab. 5.2, případ (i))
%   Ce = 1.00 — kategorie terénu III "normal" (Tab. 5.1)
%   C_t = 1.0 — zateplená střecha (Tab. D.1)
mcOpts.mu1 = 0.80;   % tvarový součinitel sněhu (prEN Tab. 5.2)
mcOpts.Ce  = 1.00;   % součinitel expozice (prEN Tab. 5.1)

results = systemReliabilityFn(nodes, members, sections, kinematic, loadParams, mcOpts);
% reliabilityReportFn(results, sections, loadParams);
reliabilityReportHtmlFn(results, params, nodes, members, sections, loadParams);
convergencePlotFn(results);


plotTrussBetaFn(nodes, members, results, kinematic);

%% ── Srovnání deterministického a probabilistického posudku ────────────
fprintf('\n--- Srovnání ---\n');
fprintf('  Deterministický max util:  %.3f\n', max(detResults.util_max));
fprintf('  Probabilistický β:         %.3f\n', results.beta);
fprintf('  β_cíl (JCSS, systém):      4.100\n');

if max(detResults.util_max) <= 1.0 && results.beta >= 4.1
    fprintf('  → Oba posudky: VYHOVUJE\n');
elseif max(detResults.util_max) > 1.0 && results.beta < 4.1
    fprintf('  → Oba posudky: NEVYHOVUJE\n');
else
    fprintf('  → Posudky se LIŠÍ — dílčí součinitele vs. spolehlivost\n');
end
