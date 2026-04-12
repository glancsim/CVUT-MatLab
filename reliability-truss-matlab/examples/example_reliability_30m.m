% example_reliability_30m.m
%
% Spolehlivostní analýza příhradového vazníku metodou Monte Carlo (UQLab).
%
% Využívá stejnou geometrii jako en-truss-design-matlab/examples/example_truss_hall_30m.m:
%   - 24m Warren inverted vazník, S355, CHS průřezy
%   - Zatížení: gravitace (G) + sníh (S) — bez větru
%   - Sériový systém: selhání jednoho prutu = kolaps
%
% Náhodné veličiny dle JRC TR "Reliability background of the Eurocodes" (2024),
% Table 3.7, Annex A + EN 1991-1-3:2025.
%
% Cílový index spolehlivosti: β_t = 3.8 (CC2, referenční období 50 let)
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
params.span            = 24;      % [m]
params.slope           = 0.05;    % [-]  5% sklon
params.purlin_spacing  = 3;       % [m]  rozteč vaznic
params.h_support       = 1.8;     % [m]  výška v uložení
params.truss_spacing   = 6.6;     % [m]  vzdálenost vazníků
params.f_y             = 355e6;   % [Pa] S355
params.E               = 210e9;   % [Pa]
params.g_roof          = 0.23;    % [kN/m²] plášť
params.g_purlins       = 0.09;    % [kN/m] vaznice
params.s_k             = 1.0;     % [kN/m²] sníh char. (na zemi)
params.w_suction       = 0.48;    % [kN/m²] sání (nepoužito v reliabilitě)
params.sections        = sections;
params.topology        = 'warren_inverted';
params.warren_verticals = true;
params.diag_sections   = [3 3 4 4];
params.vert_sections   = 5;
params.support         = 'top';

%% ── Generování geometrie ──────────────────────────────────────────────
[nodes, members, sections, kinematic, loadParams] = trussHallInputFn(params);
nmembers = numel(members.nodesHead);

fprintf('\nGeometrie: %d prutů, %d uzlů, %d průřezových skupin\n', ...
    nmembers, numel(nodes.x), loadParams.sectionGroups.nGroups);

%% ── Deterministický posudek (pro srovnání) ────────────────────────────
fprintf('\n--- Deterministický posudek EN 1993-1-1 ---\n');
detResults = designCheckFn(nodes, members, sections, kinematic, loadParams);
fprintf('  Max. využití: %.3f (prut %d)\n', max(detResults.util_max), ...
    find(detResults.util_max == max(detResults.util_max), 1));

%% ── Fáze 1: Rychlý testovací běh (1e4 vzorků) ────────────────────────
fprintf('\n====== FÁZE 1: Testovací běh (1e4 vzorků) ======\n');
mcOpts.nSamples  = 1e4;
mcOpts.batchSize = 1e3;
mcOpts.method    = 'MCS';
mcOpts.verbose   = true;

results1 = systemReliabilityFn(nodes, members, sections, kinematic, loadParams, mcOpts);
reliabilityReportFn(results1, sections, loadParams);
convergencePlotFn(results1);

%% ── Fáze 2: Střední běh (1e5 vzorků) — odkomentuj po ověření pipeline
% fprintf('\n====== FÁZE 2: Střední běh (1e5 vzorků) ======\n');
% mcOpts.nSamples  = 1e5;
% mcOpts.batchSize = 1e4;
% results2 = systemReliabilityFn(nodes, members, sections, kinematic, loadParams, mcOpts);
% reliabilityReportFn(results2, sections, loadParams);
% convergencePlotFn(results2);

%% ── Fáze 3: Plný běh (1e6+ nebo SubsetSimulation) — odkomentuj pro finální výsledky
fprintf('\n====== FÁZE 3: Plný běh ======\n');
mcOpts.nSamples  = 1e6;
mcOpts.batchSize = 1e4;
mcOpts.method    = 'Subset';             % UQLab Subset Simulation (nebo 'IS' pro Importance Sampling)
results3 = systemReliabilityFn(nodes, members, sections, kinematic, loadParams, mcOpts);
reliabilityReportFn(results3, sections, loadParams);
convergencePlotFn(results3);

%% ── Srovnání deterministického a probabilistického posudku ────────────
results = results1;   % změň na results2/results3 po odkomentování
fprintf('\n--- Srovnání ---\n');
fprintf('  Deterministický max util:  %.3f\n', max(detResults.util_max));
fprintf('  Probabilistický β:         %.3f\n', results.beta);
fprintf('  β_cíl (CC2, 50 let):       3.800\n');

if max(detResults.util_max) <= 1.0 && results.beta >= 3.8
    fprintf('  → Oba posudky: VYHOVUJE\n');
elseif max(detResults.util_max) > 1.0 && results.beta < 3.8
    fprintf('  → Oba posudky: NEVYHOVUJE\n');
else
    fprintf('  → Posudky se LIŠÍ — dílčí součinitele vs. spolehlivost\n');
end
