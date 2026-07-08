% example_reliability_PM47.m
%
% G_PM4.7 — iterativni navrh na beta_system >= 4.7.
%
% Vychazi z G_practice a postupne zvysuje prurez nejkritictejsiho prutu
% (vstupni skupiny) na nejblizsi vyssi katalogovy profil, dokud beta >= 4.7.
%
% Vysledky se ukladaji do: examples/IPW2026/reliability_results_PM47.mat
%
% Prerekvizita: UQLab framework (https://www.uqlab.com/)
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

%% ── Katalog CHS profilů (ČSN EN 10210, S355, hot-finished) ──────────
CHS = @(D, t) struct('D', D, 't', t, ...
    'A', pi/4*(D^2 - (D-2*t)^2), ...
    'I', pi/64*(D^4 - (D-2*t)^4), ...
    'i', sqrt((pi/64*(D^4-(D-2*t)^4)) / (pi/4*(D^2-(D-2*t)^2))));

catalog_raw = [ ...
    CHS(0.0337, 0.0032), ...  % TR 33.7×3.2
    CHS(0.0380, 0.0032), ...  % TR 38×3.2    <- p5 (svislice)
    CHS(0.0380, 0.0036), ...  % TR 38×3.6
    CHS(0.0424, 0.0032), ...  % TR 42.4×3.2
    CHS(0.0445, 0.0032), ...  % TR 44.5×3.2  <- p4 (vnitřní diag)
    CHS(0.0483, 0.0032), ...  % TR 48.3×3.2
    CHS(0.0483, 0.0040), ...  % TR 48.3×4.0
    CHS(0.0508, 0.0032), ...  % TR 50.8×3.2
    CHS(0.0603, 0.0032), ...  % TR 60.3×3.2
    CHS(0.0603, 0.0040), ...  % TR 60.3×4.0
    CHS(0.0700, 0.0032), ...  % TR 70×3.2
    CHS(0.0700, 0.0040), ...  % TR 70×4.0
    CHS(0.0761, 0.0032), ...  % TR 76.1×3.2
    CHS(0.0761, 0.0040), ...  % TR 76.1×4.0
    CHS(0.0825, 0.0032), ...  % TR 82.5×3.2
    CHS(0.0825, 0.0036), ...  % TR 82.5×3.6  <- p3 (vnější diag)
    CHS(0.0889, 0.0032), ...  % TR 88.9×3.2
    CHS(0.0889, 0.0040), ...  % TR 88.9×4.0
    CHS(0.0889, 0.0050), ...  % TR 88.9×5.0
    CHS(0.1016, 0.0040), ...  % TR 101.6×4.0
    CHS(0.1016, 0.0050), ...  % TR 101.6×5.0
    CHS(0.1080, 0.0040), ...  % TR 108×4.0
    CHS(0.1080, 0.0050), ...  % TR 108×5.0   <- p1 (horní pás)
    CHS(0.1143, 0.0040), ...  % TR 114.3×4.0
    CHS(0.1143, 0.0050), ...  % TR 114.3×5.0
    CHS(0.1270, 0.0050), ...  % TR 127×5.0
    CHS(0.1397, 0.0050), ...  % TR 139.7×5.0
    CHS(0.1590, 0.0050), ...  % TR 159×5.0   <- p2 (dolní pás)
    CHS(0.1683, 0.0050), ...  % TR 168.3×5.0
    CHS(0.1930, 0.0063), ...  % TR 193.7×6.3
];

% Seradit vzestupne dle plochy A
[~, sort_idx] = sort([catalog_raw.A]);
catalog = catalog_raw(sort_idx);
assert(issorted([catalog.A]), 'Chyba razeni — interni chyba skriptu');

nCatalog     = numel(catalog);
nInputGroups = 5;

groupNames = {'horni pas', 'dolni pas', 'vnejsi diagonaly', 'vnitrni diagonaly', 'svislice'};

% Najit indexy puvodnich profilu dynamicky
findProfile = @(D, t) find(abs([catalog.D]-D) < 1e-7 & abs([catalog.t]-t) < 1e-7);

idx_p1 = findProfile(0.1080, 0.0050);   % TR 108x5
idx_p2 = findProfile(0.1590, 0.0050);   % TR 159x5
idx_p3 = findProfile(0.0825, 0.0036);   % TR 82.5x3.6
idx_p4 = findProfile(0.0445, 0.0032);   % TR 44.5x3.2
idx_p5 = findProfile(0.0380, 0.0032);   % TR 38x3.2

assert(~isempty(idx_p1) && ~isempty(idx_p2) && ~isempty(idx_p3) && ...
       ~isempty(idx_p4) && ~isempty(idx_p5), ...
    'Puvodni profily nenalezeny v katalogu');

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
params.topology        = 'warren_inverted';
params.warren_verticals = true;
params.diag_sections   = [3 3 4 4];
params.vert_sections   = 5;
params.support         = 'top';

%% ── Mapování skupin (výpočet jednou pro stabilní topologii) ───────────
params.sections = buildSections(catalog, [idx_p1, idx_p2, idx_p3, idx_p4, idx_p5]);
[~, members_ref, ~, ~, loadParams_ref] = trussHallInputFn(params);

sg = loadParams_ref.sectionGroups;
nDiag   = sg.nDiag;
nVert   = sg.nVert;
nGroups = sg.nGroups;

diagMap_full = params.diag_sections(:)';
if isscalar(diagMap_full), diagMap_full = diagMap_full * ones(1, nDiag); end
vertMap_full = params.vert_sections(:)';
if isscalar(vertMap_full), vertMap_full = vertMap_full * ones(1, nVert); end

output_to_input = zeros(nGroups, 1);
output_to_input(1) = 1;
output_to_input(2) = 2;
for dd = 1:nDiag
    output_to_input(2 + dd) = diagMap_full(dd);
end
for vv = 1:nVert
    output_to_input(2 + nDiag + vv) = vertMap_full(vv);
end

fprintf('Geometrie: %d prutu, %d skupin\n', numel(members_ref.nodesHead), nGroups);

%% ── Spolehlivostní nastavení ──────────────────────────────────────────
beta_target = 4.7;
MAX_ITER    = 20;

mcOpts.nSamples  = 1e7;
mcOpts.batchSize = 1e6;
mcOpts.method    = 'MCS';
mcOpts.rvOpts.Q1_mean = 0.31;
mcOpts.rvOpts.Q1_cov  = 0.61;
mcOpts.mu1 = 0.80;
mcOpts.Ce  = 1.00;

%% ── Počáteční profily = G_practice ────────────────────────────────────
current_profiles = [idx_p1, idx_p2, idx_p3, idx_p4, idx_p5];

history = struct('iter', {}, 'beta', {}, 'group_upgraded', {}, ...
                 'old_profile', {}, 'new_profile', {}, 'G_weight', {});

%% ── Iterační smyčka ───────────────────────────────────────────────────
fprintf('\n=== Iterativni navrh G_PM4.7 (cil beta >= %.1f) ===\n', beta_target);

nodes_i = []; members_i = []; sections_i = []; kinematic_i = []; loadParams_i = [];
results_i = struct('beta', 0);

for iter = 1:MAX_ITER
    params.sections = buildSections(catalog, current_profiles);
    [nodes_i, members_i, sections_i, kinematic_i, loadParams_i] = ...
        trussHallInputFn(params);

    fprintf('\n--- Iterace %d ---\n', iter);
    fprintf('Profily: %s\n', profileName(catalog, current_profiles));

    results_i = systemReliabilityFn(nodes_i, members_i, sections_i, ...
        kinematic_i, loadParams_i, mcOpts);

    beta_i = results_i.beta;
    G_i    = trussWeight(sections_i, members_i, nodes_i);

    fprintf('beta = %.3f,  G = %.1f kg\n', beta_i, G_i);

    history(iter).iter    = iter;
    history(iter).beta    = beta_i;
    history(iter).G_weight = G_i;
    history(iter).group_upgraded = 0;
    history(iter).old_profile    = 0;
    history(iter).new_profile    = 0;

    if beta_i >= beta_target
        fprintf('-> Cil beta >= %.1f dosažen.\n', beta_target);
        break;
    end

    % Nejkritičtější prut → vstupní skupina
    crit_pct = results_i.member.critical_pct;
    [~, crit_member]  = max(crit_pct);
    crit_group_out    = members_i.sections(crit_member);
    crit_group_in     = output_to_input(crit_group_out);

    old_idx = current_profiles(crit_group_in);
    if old_idx >= nCatalog
        error('Katalog vycerpan pro skupinu %d — nelze dal zvysovat.', crit_group_in);
    end
    new_idx = old_idx + 1;
    current_profiles(crit_group_in) = new_idx;

    history(iter).group_upgraded = crit_group_in;
    history(iter).old_profile    = old_idx;
    history(iter).new_profile    = new_idx;

    fprintf('-> Zvysuji skupinu %d (%s): %s -> %s\n', ...
        crit_group_in, groupNames{crit_group_in}, ...
        profileName(catalog, old_idx), profileName(catalog, new_idx));
end

if results_i.beta < beta_target
    warning('Max. pocet iteraci dosažen bez splneni beta >= %.1f.', beta_target);
end

%% ── Výsledky ──────────────────────────────────────────────────────────
detResults_PM47 = designCheckFn(nodes_i, members_i, sections_i, kinematic_i, loadParams_i);
results_PM47 = results_i;
G_PM47 = trussWeight(sections_i, members_i, nodes_i);

fprintf('\n=== G_PM4.7 vysledky ===\n');
for g = 1:nInputGroups
    gm = (output_to_input(members_i.sections) == g);
    fprintf('  Skupina %d (%s): %s, eta_max = %.3f\n', g, groupNames{g}, ...
        profileName(catalog, current_profiles(g)), max(detResults_PM47.util_max(gm)));
end
fprintf('  Max. vyuziti eta:   %.3f\n', max(detResults_PM47.util_max));
fprintf('  Hmotnost G_PM4.7:   %.1f kg\n', G_PM47);
fprintf('  Systemovy beta:     %.3f\n', results_PM47.beta);

fprintf('\nHistorie iteraci:\n');
fprintf('  %4s  %7s  %8s  %s\n', 'iter', 'beta', 'G [kg]', 'Upgrade');
for k = 1:numel(history)
    if history(k).group_upgraded > 0
        upg = sprintf('Skup.%d: %s -> %s', history(k).group_upgraded, ...
            profileName(catalog, history(k).old_profile), ...
            profileName(catalog, history(k).new_profile));
    else
        upg = '—';
    end
    fprintf('  %4d  %7.3f  %8.1f  %s\n', history(k).iter, history(k).beta, history(k).G_weight, upg);
end

%% ── Uložení ───────────────────────────────────────────────────────────
save(fullfile(thisDir, 'reliability_results_PM47.mat'), ...
    'results_PM47', 'detResults_PM47', 'G_PM47', 'current_profiles', ...
    'catalog', 'history');

fprintf('\nUlozeno: reliability_results_PM47.mat\n');

%% ── Lokální funkce ────────────────────────────────────────────────────

function s = buildSections(catalog, prof_idx)
    E_steel = 210e9;
    n = numel(prof_idx);
    s.A        = arrayfun(@(k) catalog(k).A, prof_idx(:));
    s.I        = arrayfun(@(k) catalog(k).I, prof_idx(:));
    s.i_radius = arrayfun(@(k) catalog(k).i, prof_idx(:));
    s.D        = arrayfun(@(k) catalog(k).D, prof_idx(:));
    s.t        = arrayfun(@(k) catalog(k).t, prof_idx(:));
    s.E        = E_steel * ones(n, 1);
    s.curve    = repmat({'a'}, n, 1);
end

function name = profileName(catalog, idx)
    if isscalar(idx)
        name = sprintf('TR %.1fx%.1f', catalog(idx).D*1000, catalog(idx).t*1000);
    else
        parts = arrayfun(@(k) sprintf('TR %.1fx%.1f', catalog(k).D*1000, catalog(k).t*1000), ...
            idx(:)', 'UniformOutput', false);
        name = strjoin(parts, ' | ');
    end
end

function G = trussWeight(sections, members, nodes)
    dx = nodes.x(members.nodesEnd) - nodes.x(members.nodesHead);
    dz = nodes.z(members.nodesEnd) - nodes.z(members.nodesHead);
    L  = sqrt(dx.^2 + dz.^2);
    rho_steel = 7850;
    G = sum(sections.A(members.sections) .* L) * rho_steel;
end
