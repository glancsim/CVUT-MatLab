% example_reliability_24m_improved.m
%
% Spolehlivostní analýza příhradového vazníku — VYLEPŠENÝ NÁVRH.
% Svislice změněny z TR 38×3.2 na TR 38×3.6.
%
% Výsledky se ukládají do reliability_results_improved.mat
% pro srovnání s původním návrhem v figures_paper.m.
%
% (c) S. Glanc, 2026

clear; close all;

%% ── Cesty k modulům ──────────────────────────────────────────────────
thisDir  = fileparts(mfilename('fullpath'));
if isempty(thisDir), thisDir = pwd; end
root     = fileparts(fileparts(thisDir));
srcDir   = fullfile(root, 'src');
designDir = fullfile(root, '..', 'en-truss-design-matlab', 'src');
femDir   = fullfile(root, '..', 'fem-2d-truss-matlab', 'src');

addpath(srcDir);
addpath(designDir);
addpath(femDir);

% Inicializace UQLab
uqlab_core = 'C:\Install\UQLab\core';
if exist(uqlab_core, 'dir') && isempty(which('uqlab'))
    addpath(uqlab_core);
end
uqlab;

%% ── Průřezy ──────────────────────────────────────────────────────────
CHS = @(D, t) struct( ...
    'D', D, 't', t, ...
    'A', pi/4*(D^2 - (D-2*t)^2), ...
    'I', pi/64*(D^4 - (D-2*t)^4), ...
    'i', sqrt( (pi/64*(D^4-(D-2*t)^4)) / (pi/4*(D^2-(D-2*t)^2)) ));

p1 = CHS(0.108,  0.005);    % TR 108×5     — horní pás
p2 = CHS(0.159,  0.005);    % TR 159×5     — dolní pás
p3 = CHS(0.0825, 0.0036);   % TR 82.5×3.6  — vnější diagonály
p4 = CHS(0.0445, 0.0032);   % TR 44.5×3.2  — vnitřní diagonály
p5 = CHS(0.038,  0.0036);   % TR 38×3.6    — svislice (změna: původně TR 38×3.2)

profiles = [p1 p2 p3 p4 p5];
nProf = numel(profiles);

E_steel = 210e9;
sections.A        = [profiles.A]';
sections.E        = E_steel * ones(nProf, 1);
sections.I        = [profiles.I]';
sections.i_radius = [profiles.i]';
sections.curve    = repmat({'a'}, nProf, 1);
sections.D        = [profiles.D]';
sections.t        = [profiles.t]';

%% ── Parametry haly ────────────────────────────────────────────────────
params.span            = 24;
params.slope           = 0.05;
params.purlin_spacing  = 3;
params.h_support       = 1.8;
params.truss_spacing   = 6.6;
params.f_y             = 355e6;
params.E               = 210e9;
params.g_roof          = 0.23;
params.g_purlins       = 0.09;
params.s_k             = 1.0;
params.w_suction       = 0.48;
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

%% ── Srovnání materiálu ────────────────────────────────────────────────
p5_orig = CHS(0.038, 0.0032);
p5_new  = CHS(0.038, 0.0036);
dA_pct = (p5_new.A - p5_orig.A) / p5_orig.A * 100;

% Délky prutů (vzdálenost uzlů, přes dx a dz)
dx = nodes.x(members.nodesEnd) - nodes.x(members.nodesHead);
dz = nodes.z(members.nodesEnd) - nodes.z(members.nodesHead);
L_mem = sqrt(dx.^2 + dz.^2);   % (nmembers×1)

% Celkový objem: A_sec(group) × L(member), indexováno přes members.sections
A_sec_orig = sections.A;                          % kopie průřezových ploch
A_sec_orig(params.vert_sections) = p5_orig.A;    % vrať skupinu svislic na původní 38×3.2
A_per_mem_orig = A_sec_orig(members.sections);    % (nmembers×1)
A_per_mem_new  = sections.A(members.sections);    % (nmembers×1)
V_orig = sum(A_per_mem_orig .* L_mem);
V_new  = sum(A_per_mem_new  .* L_mem);
dV_pct = (V_new - V_orig) / V_orig * 100;

fprintf('\n--- Srovnání průřezů svislic ---\n');
fprintf('  TR 38×3.2:  A = %.2f cm²\n', p5_orig.A * 1e4);
fprintf('  TR 38×3.6:  A = %.2f cm²  (+%.1f %%)\n', p5_new.A * 1e4, dA_pct);
fprintf('  Celkový objem ocel: původní = %.4f m³, nový = %.4f m³  (+%.2f %%)\n', ...
    V_orig, V_new, dV_pct);

%% ── Deterministický posudek ───────────────────────────────────────────
fprintf('\n--- Deterministický posudek EN 1993-1-1 (vylepšený návrh) ---\n');
detResults = designCheckFn(nodes, members, sections, kinematic, loadParams);
fprintf('  Max. využití: %.3f (prut %d)\n', max(detResults.util_max), ...
    find(detResults.util_max == max(detResults.util_max), 1));

%% ── Spolehlivostní posudek ────────────────────────────────────────────
fprintf('\n====== MCS — vylepšený návrh ======\n');
mcOpts.nSamples  = 1e7;   % 1e7 stačí pro srovnání s původním návrhem
mcOpts.batchSize = 1e6;
mcOpts.method    = 'MCS';
mcOpts.rvOpts.Q1_mean = 0.31;
mcOpts.rvOpts.Q1_cov  = 0.61;
mcOpts.mu1 = 0.80;
mcOpts.Ce  = 1.00;

results = systemReliabilityFn(nodes, members, sections, kinematic, loadParams, mcOpts);

fprintf('\n  Původní návrh:    β = 4.459  (TR 38×3.2 svislice)\n');
fprintf('  Vylepšený návrh:  β = %.3f  (TR 38×3.6 svislice)\n', results.beta);

% Uložení pro figures_paper.m
save(fullfile(thisDir, 'reliability_results_improved.mat'), 'results', 'detResults');
fprintf('\nVýsledky uloženy: reliability_results_improved.mat\n');
