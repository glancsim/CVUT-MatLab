% example_reliability_PFM.m
%
% G_PFM — navrh na hranici EC (eta_max <= 1.0 pro kazdou skupinu prurezu).
%
% Algoritmus:
%   SU => N_Ed = N_Ed_fixed + gamma_G * delta_A * N_sw_unit_g (linearita)
%
%   Pre-compute (10 FEM behu celkem):
%     - N_Ed_orig(p,ic)    ... 5 FEM s originalni vlastni tihou (1 na KZS)
%     - N_sw_unit(p,g)     ... 5 FEM s jednotkovou (A=1 m^2) vlastni tihou
%                             skupiny g (sekce-nezavisle, presne pro SU)
%
%   Vnitrni smycka (zadny FEM):
%     N_Ed_trial = N_Ed_orig + gamma_G * (A_k - A_0g) * N_sw_unit_g
%     -> sectionCheckFn: aritmetika
%
%   Garantuje beta_practice >= beta_PFM (PFM vzdy lehci nebo stejny).
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

%% ── Katalog CHS (ČSN EN 10210, S355, hot-finished) ──────────────────
CHS = @(D, t) struct('D', D, 't', t, ...
    'A', pi/4*(D^2 - (D-2*t)^2), ...
    'I', pi/64*(D^4 - (D-2*t)^4), ...
    'i', sqrt((pi/64*(D^4-(D-2*t)^4)) / (pi/4*(D^2-(D-2*t)^2))));

catalog_raw = [ ...
    CHS(0.0337, 0.0032), CHS(0.0380, 0.0032), CHS(0.0380, 0.0036), ...
    CHS(0.0424, 0.0032), CHS(0.0445, 0.0032), CHS(0.0483, 0.0032), ...
    CHS(0.0483, 0.0040), CHS(0.0508, 0.0032), CHS(0.0603, 0.0032), ...
    CHS(0.0603, 0.0040), CHS(0.0700, 0.0032), CHS(0.0700, 0.0040), ...
    CHS(0.0761, 0.0032), CHS(0.0761, 0.0040), CHS(0.0825, 0.0032), ...
    CHS(0.0825, 0.0036), CHS(0.0889, 0.0032), CHS(0.0889, 0.0040), ...
    CHS(0.0889, 0.0050), CHS(0.1016, 0.0040), CHS(0.1016, 0.0050), ...
    CHS(0.1080, 0.0040), CHS(0.1080, 0.0050), CHS(0.1143, 0.0040), ...
    CHS(0.1143, 0.0050), CHS(0.1270, 0.0050), CHS(0.1397, 0.0050), ...
    CHS(0.1590, 0.0050), CHS(0.1683, 0.0050), CHS(0.1930, 0.0063), ...
];

[~, si] = sort([catalog_raw.A]);
catalog  = catalog_raw(si);
assert(issorted([catalog.A]), 'Interni chyba razeni katalogu');
nCatalog = numel(catalog);

findProf = @(D, t) find(abs([catalog.D]-D) < 1e-7 & abs([catalog.t]-t) < 1e-7);
idx0 = [findProf(0.1080,0.0050), findProf(0.1590,0.0050), ...
        findProf(0.0825,0.0036), findProf(0.0445,0.0032), findProf(0.0380,0.0032)];
assert(numel(idx0) == 5, 'Puvodni profily nenalezeny v katalogu');

nInputGroups = 5;
groupNames   = {'horni pas','dolni pas','vnejsi diag','vnitrni diag','svislice'};

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
params.sections        = buildSections(catalog, idx0);
params.topology        = 'warren_inverted';
params.warren_verticals = true;
params.diag_sections   = [3 3 4 4];
params.vert_sections   = 5;
params.support         = 'top';

%% ── Geometrie (jednou, topologie se nemeni) ───────────────────────────
[nodes, members, sections, kinematic, loadParams] = trussHallInputFn(params);
nmembers = numel(members.nodesHead);

sg = loadParams.sectionGroups;
nDiag = sg.nDiag; nVert = sg.nVert; nGroups = sg.nGroups;

diagMap = params.diag_sections(:)';
if isscalar(diagMap), diagMap = diagMap * ones(1, nDiag); end
vertMap = params.vert_sections(:)';
if isscalar(vertMap), vertMap = vertMap * ones(1, nVert); end

out2in = zeros(nGroups, 1);
out2in(1) = 1; out2in(2) = 2;
for d = 1:nDiag, out2in(2+d)       = diagMap(d); end
for v = 1:nVert, out2in(2+nDiag+v) = vertMap(v); end

fprintf('Geometrie: %d prutu, %d uzlu, %d skupin\n', nmembers, numel(nodes.x), nGroups);

%% ── Pre-compute: N_Ed pro vsechny KZS s originalni vlastni tihou ─────
% 5 FEM behu — N_Ed_orig(p, ic) [N], kladne = tah
combos  = loadCombinationsFn(loadParams);
ncombos = numel(combos);
gamma_G = arrayfun(@(ic) combos{ic}.gamma_G, 1:ncombos);   % [1.35,1.35,1.35,1,1]

N_Ed_orig = zeros(nmembers, ncombos);
for ic = 1:ncombos
    [~, ef] = linearSolverFn(sections, nodes, kinematic, members, combos{ic}.loads);
    N_Ed_orig(:, ic) = ef.local(1, :)';   % [N]
end
fprintf('N_Ed originalu predpocitany (%d KZS).\n', ncombos);

%% ── Pre-compute: jednotkovy self-weight vliv per vstupni skupina ─────
% 5 FEM behu — N_sw_unit(p, g) [N/m^2]
%
% N_sw_unit(p,g) = zmena N_Ed v prutu p pri pridani 1 m^2 plochy prurezu
% ke vsem prutum skupiny g (pri gamma_G = 1).
% Pro trial k v skupine g:
%   N_Ed_trial(p,ic) = N_Ed_orig(p,ic)
%                    + gamma_G(ic) * (catalog(k).A - catalog(idx0(g)).A) * N_sw_unit(p,g)

rho_steel = 7850; g_grav = 9.81;
N_sw_unit = zeros(nmembers, nInputGroups);

dx_all = nodes.x(members.nodesEnd) - nodes.x(members.nodesHead);
dz_all = nodes.z(members.nodesEnd) - nodes.z(members.nodesHead);
L_all  = sqrt(dx_all.^2 + dz_all.^2);

for g = 1:nInputGroups
    gm = find(out2in(members.sections) == g);

    % Nodalni zatizeni: F = 1 [m^2] * L * rho * g / 2 na kazdy konec [N]
    all_nodes  = zeros(2*numel(gm), 1);
    all_values = zeros(2*numel(gm), 1);
    for ki = 1:numel(gm)
        p = gm(ki);
        F_half = 1.0 * L_all(p) * rho_steel * g_grav / 2;   % [N] per unit area
        all_nodes(2*ki-1) = members.nodesHead(p);
        all_nodes(2*ki)   = members.nodesEnd(p);
        all_values(2*ki-1) = -F_half;   % downward
        all_values(2*ki)   = -F_half;
    end

    lds_unit.x.nodes = [];  lds_unit.x.value = [];
    lds_unit.z.nodes = all_nodes;
    lds_unit.z.value = all_values;

    [~, ef_g] = linearSolverFn(sections, nodes, kinematic, members, lds_unit);
    N_sw_unit(:, g) = ef_g.local(1, :)';   % [N per m^2 per group]
end
fprintf('Self-weight vlivove koeficienty predpocitany (%d skupin).\n', nInputGroups);

%% ── Vzperne delky (geometrie-only, jednou) ────────────────────────────
classification = memberClassificationFn(members, nodes);
Lcr = bucklingLengthsFn(members, nodes, classification, loadParams);
f_y = loadParams.f_y;

%% ── Optimalizace: min katalogovy profil pro eta <= 1.0 ───────────────
fprintf('\n=== Hledani minimalniho profilu (eta <= 1.0) ===\n');

% Precomputed baseline area per input group
A_orig = arrayfun(@(g) catalog(idx0(g)).A, 1:nInputGroups);

best_profiles = zeros(nInputGroups, 1);

for g = 1:nInputGroups
    gm = find(out2in(members.sections) == g);
    fprintf('\nSkupina %d (%s), %d prutu:\n', g, groupNames{g}, numel(gm));

    found = false;
    for k = 1:nCatalog
        prof    = catalog(k);
        delta_A = prof.A - A_orig(g);

        % Opravena N_Ed pro trial profil k ve skupine g
        N_Ed_trial = N_Ed_orig;   % (nmembers x ncombos) [N]
        for ic = 1:ncombos
            N_Ed_trial(:, ic) = N_Ed_orig(:, ic) + gamma_G(ic) * delta_A * N_sw_unit(:, g);
        end

        eta_max = 0;
        for p = gm'
            L_cr_p = Lcr.governing(p);
            for ic = 1:ncombos
                r = sectionCheckFn(N_Ed_trial(p, ic), prof.A, prof.i, f_y, L_cr_p, 'a', prof.D, prof.t);
                eta_max = max(eta_max, r.util_max);
            end
        end

        fprintf('  %s: eta = %.3f', profName(prof), eta_max);
        if eta_max <= 1.0
            best_profiles(g) = k;
            found = true;
            fprintf('  -> OK\n');
            break;
        else
            fprintf('\n');
        end
    end

    if ~found
        error('Skupina %d: zadny profil v katalogu nevyhovuje.', g);
    end
end

%% ── Overeni kombinovaneho navrhu ──────────────────────────────────────
fprintf('\n=== Overeni kombinovaneho navrhu G_PFM ===\n');
params_PFM          = params;
params_PFM.sections = buildSections(catalog, best_profiles);

[nodes_PFM, members_PFM, sections_PFM, kinematic_PFM, loadParams_PFM] = ...
    trussHallInputFn(params_PFM);

detResults_PFM = designCheckFn(nodes_PFM, members_PFM, sections_PFM, ...
    kinematic_PFM, loadParams_PFM);

fprintf('\nVysledne profily G_PFM:\n');
for g = 1:nInputGroups
    gm = (out2in(members_PFM.sections) == g);
    fprintf('  %d (%s): %s  eta_max = %.3f\n', g, groupNames{g}, ...
        profName(catalog(best_profiles(g))), max(detResults_PFM.util_max(gm)));
end
fprintf('  Celkovy eta_max: %.3f\n', max(detResults_PFM.util_max));

G_PFM = trussWeight(sections_PFM, members_PFM, nodes_PFM);
fprintf('  Hmotnost: %.1f kg\n', G_PFM);

%% ── Spolehlivostni analyza ────────────────────────────────────────────
fprintf('\n=== Spolehlivostni analyza G_PFM (1e7 vzorku) ===\n');
mcOpts.nSamples       = 1e7;
mcOpts.batchSize      = 1e6;
mcOpts.method         = 'MCS';
mcOpts.rvOpts.Q1_mean = 0.31;
mcOpts.rvOpts.Q1_cov  = 0.61;
mcOpts.mu1 = 0.80;
mcOpts.Ce  = 1.00;

results_PFM = systemReliabilityFn(nodes_PFM, members_PFM, sections_PFM, ...
    kinematic_PFM, loadParams_PFM, mcOpts);

%% ── Vystup a ulozeni ──────────────────────────────────────────────────
fprintf('\n=== G_PFM vysledky ===\n');
for g = 1:nInputGroups
    fprintf('  Skupina %d (%s): %s\n', g, groupNames{g}, profName(catalog(best_profiles(g))));
end
fprintf('  eta_max:      %.3f\n', max(detResults_PFM.util_max));
fprintf('  Hmotnost:     %.1f kg\n', G_PFM);
fprintf('  Systemovy b:  %.3f\n', results_PFM.beta);

save(fullfile(thisDir, 'reliability_results_PFM.mat'), ...
    'results_PFM', 'detResults_PFM', 'G_PFM', 'best_profiles', 'catalog');
fprintf('\nUlozeno: reliability_results_PFM.mat\n');

%% ── Lokalni funkce ────────────────────────────────────────────────────

function s = buildSections(catalog, prof_idx)
    n = numel(prof_idx);
    s.A        = arrayfun(@(k) catalog(k).A, prof_idx(:));
    s.I        = arrayfun(@(k) catalog(k).I, prof_idx(:));
    s.i_radius = arrayfun(@(k) catalog(k).i, prof_idx(:));
    s.D        = arrayfun(@(k) catalog(k).D, prof_idx(:));
    s.t        = arrayfun(@(k) catalog(k).t, prof_idx(:));
    s.E        = 210e9 * ones(n, 1);
    s.curve    = repmat({'a'}, n, 1);
end

function name = profName(prof)
    name = sprintf('TR %.1fx%.1f', prof.D*1000, prof.t*1000);
end

function G = trussWeight(sections, members, nodes)
    dx = nodes.x(members.nodesEnd) - nodes.x(members.nodesHead);
    dz = nodes.z(members.nodesEnd) - nodes.z(members.nodesHead);
    G  = sum(sections.A(members.sections) .* sqrt(dx.^2+dz.^2)) * 7850;
end
