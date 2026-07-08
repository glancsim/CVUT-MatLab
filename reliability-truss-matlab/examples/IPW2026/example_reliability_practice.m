% example_reliability_practice.m
%
% G_practice — spolehlivostni analyza puvodnich profilu (1e7 vzorku).
% Ekvivalentni podmínky jako G_PFM a G_PM4.7 pro porovnani.
%
% (c) S. Glanc, 2026

clear; close all;

%% ── Cesty k modulům ──────────────────────────────────────────────────
thisDir  = fileparts(mfilename('fullpath'));
if isempty(thisDir), thisDir = pwd; end
root     = fileparts(fileparts(thisDir));
addpath(fullfile(root, 'src'));
addpath(fullfile(root, '..', 'en-truss-design-matlab', 'src'));
addpath(fullfile(root, '..', 'fem-2d-truss-matlab', 'src'));

uqlab_core = 'C:\Install\UQLab\core';
if exist(uqlab_core, 'dir') && isempty(which('uqlab')), addpath(uqlab_core); end
uqlab;

%% ── Průřezy G_practice ────────────────────────────────────────────────
CHS = @(D, t) struct('D', D, 't', t, ...
    'A', pi/4*(D^2-(D-2*t)^2), ...
    'I', pi/64*(D^4-(D-2*t)^4), ...
    'i', sqrt((pi/64*(D^4-(D-2*t)^4))/(pi/4*(D^2-(D-2*t)^2))));

p1 = CHS(0.1080, 0.0050);   % TR 108×5   — horni pas
p2 = CHS(0.1590, 0.0050);   % TR 159×5   — dolni pas
p3 = CHS(0.0825, 0.0036);   % TR 82.5×3.6 — vnejsi diag
p4 = CHS(0.0445, 0.0032);   % TR 44.5×3.2 — vnitrni diag
p5 = CHS(0.0380, 0.0032);   % TR 38×3.2  — svislice

n = 5;
sections.A        = [p1.A; p2.A; p3.A; p4.A; p5.A];
sections.I        = [p1.I; p2.I; p3.I; p4.I; p5.I];
sections.i_radius = [p1.i; p2.i; p3.i; p4.i; p5.i];
sections.D        = [p1.D; p2.D; p3.D; p4.D; p5.D];
sections.t        = [p1.t; p2.t; p3.t; p4.t; p5.t];
sections.E        = 210e9 * ones(n,1);
sections.curve    = repmat({'a'}, n, 1);

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

%% ── Geometrie ─────────────────────────────────────────────────────────
[nodes, members, sections, kinematic, loadParams] = trussHallInputFn(params);

%% ── Deterministicky posudek ───────────────────────────────────────────
detResults_practice = designCheckFn(nodes, members, sections, kinematic, loadParams);
G_practice = trussWeight(sections, members, nodes);

fprintf('Max. vyuziti: %.3f (prut %d)\n', max(detResults_practice.util_max), ...
    find(detResults_practice.util_max == max(detResults_practice.util_max), 1));
fprintf('Hmotnost: %.1f kg\n', G_practice);

%% ── Spolehlivostni analyza ────────────────────────────────────────────
fprintf('\n=== Spolehlivostni analyza G_practice (1e7 vzorku) ===\n');
mcOpts.nSamples       = 1e7;
mcOpts.batchSize      = 1e6;
mcOpts.method         = 'MCS';
mcOpts.rvOpts.Q1_mean = 0.31;
mcOpts.rvOpts.Q1_cov  = 0.61;
mcOpts.mu1 = 0.80;
mcOpts.Ce  = 1.00;

results_practice = systemReliabilityFn(nodes, members, sections, kinematic, loadParams, mcOpts);

fprintf('\n=== G_practice vysledky ===\n');
fprintf('  Profily: TR 108x5 | TR 159x5 | TR 82.5x3.6 | TR 44.5x3.2 | TR 38x3.2\n');
fprintf('  eta_max:     %.3f\n', max(detResults_practice.util_max));
fprintf('  Hmotnost:    %.1f kg\n', G_practice);
fprintf('  Systemovy b: %.3f\n', results_practice.beta);

save(fullfile(thisDir, 'reliability_results_practice.mat'), ...
    'results_practice', 'detResults_practice', 'G_practice');
fprintf('\nUlozeno: reliability_results_practice.mat\n');

%% ── Lokalni funkce ────────────────────────────────────────────────────
function G = trussWeight(sections, members, nodes)
    dx = nodes.x(members.nodesEnd) - nodes.x(members.nodesHead);
    dz = nodes.z(members.nodesEnd) - nodes.z(members.nodesHead);
    G  = sum(sections.A(members.sections) .* sqrt(dx.^2+dz.^2)) * 7850;
end
