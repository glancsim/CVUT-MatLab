% compare_designs.m
%
% Srovnání tří návrhů: G_practice, G_PFM, G_PM4.7
%
% Prerekvizita: spustit nejprve:
%   example_reliability_24m.m  → reliability_results.mat
%   example_reliability_PFM.m  → reliability_results_PFM.mat
%   example_reliability_PM47.m → reliability_results_PM47.mat
%
% (c) S. Glanc, 2026

thisDir = fileparts(mfilename('fullpath'));
if isempty(thisDir), thisDir = pwd; end

%% ── Načtení výsledků ─────────────────────────────────────────────────
d0   = load(fullfile(thisDir, 'reliability_results_practice.mat'));
dPFM = load(fullfile(thisDir, 'reliability_results_PFM.mat'));
dP47 = load(fullfile(thisDir, 'reliability_results_PM47.mat'));

%% ── Hmotnosti ─────────────────────────────────────────────────────────
G_practice_weight = d0.G_practice;
G_PFM_weight      = dPFM.G_PFM;
G_PM47_weight     = dP47.G_PM47;

%% ── Indexy spolehlivosti ──────────────────────────────────────────────
G_practice_beta = d0.results_practice.beta;
G_PFM_beta      = dPFM.results_PFM.beta;
G_PM47_beta     = dP47.results_PM47.beta;

%% ── Využití průřezů ───────────────────────────────────────────────────
G_practice_eta = max(d0.detResults_practice.util_max);
G_PFM_eta      = max(dPFM.detResults_PFM.util_max);
G_PM47_eta     = max(dP47.detResults_PM47.util_max);

%% ── Výpis tabulky ─────────────────────────────────────────────────────
fprintf('\n=== SROVNÁNÍ NÁVRHŮ (vsechny 1e7 vzorku) ===\n');
fprintf('%-12s  %8s  %8s  %6s\n', 'Návrh', 'β_system', 'G [kg]', 'η_max');
fprintf('%s\n', repmat('-', 1, 45));
fprintf('%-12s  %8.3f  %8.1f  %6.3f\n', 'G_practice', G_practice_beta, G_practice_weight, G_practice_eta);
fprintf('%-12s  %8.3f  %8.1f  %6.3f\n', 'G_PFM',      G_PFM_beta,      G_PFM_weight,      G_PFM_eta);
fprintf('%-12s  %8.3f  %8.1f  %6.3f\n', 'G_PM4.7',    G_PM47_beta,     G_PM47_weight,      G_PM47_eta);

fprintf('%s\n', repmat('-', 1, 65));

%% ── Uložení srovnávací tabulky ────────────────────────────────────────
save(fullfile(thisDir, 'comparison_table.mat'), ...
    'G_practice_beta', 'G_practice_weight', 'G_practice_eta', ...
    'G_PFM_beta',      'G_PFM_weight',      'G_PFM_eta', ...
    'G_PM47_beta',     'G_PM47_weight',     'G_PM47_eta');

fprintf('\nUloženo: comparison_table.mat\n');
