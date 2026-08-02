% story3_seed_stability.m
%
% Evidence for Gate 2 of MC_NEPTUN_FINDINGS.md section 9.
%
% The Warren X-brace truss shows a 6.53 % bimodality in Pf_sys across RNG
% seeds (section 4). This script checks whether the Wei & Deng (2022)
% 3-story verification example -- the paper's only published-reference
% check, cited in tab:verification -- suffers the same instability.
%
% It does not: beta_sys is stable to 2e-06 across 10 seeds, even though 20
% of its 78 cut-sets have size >= 4 and therefore go through mvncdf's
% randomised quasi-Monte Carlo path. That makes it a valid and tight gate
% for the gradient fix, and shows the Warren bimodality is a degenerate-case
% fragility (structural ties from the shared diagonal resistance) rather
% than a general breakdown.
%
% Setup replicated from examples/example_3story_truss.m (Wei & Deng 2022,
% sec. 6.2, Table 2). Reference: beta_sys = 3.001162 (their own method),
% 3.013374 (their MCS, 1e7).
%
% (c) S. Glanc, 2026

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..', '..', '..', '..');
addpath(fullfile(root, 'system-reliability-truss-matlab', 'src'));
addpath(fullfile(root, 'fem-2d-truss-matlab', 'src'));

%% geometry
nodes.x = [0; 1.219; 0; 1.219; 0; 1.219; 0; 1.219];
nodes.z = [0; 0; 0.9144; 0.9144; 1.8288; 1.8288; 2.7432; 2.7432];
kinematic.x.nodes = [1; 2];  kinematic.z.nodes = [1; 2];

members.nodesHead = [1;3;5;7;  1;2;3;4;5;6;  1;2;3;4;5;6];
members.nodesEnd  = [2;4;6;8;  3;4;5;6;7;8;  4;3;6;5;8;7];
members.nmembers  = 16;

t = zeros(16,1);
t([4,15]) = 1; t(2) = 2; t([3,9,10]) = 3; t(8) = 4;
t(1) = 5; t([7,13,14]) = 6; t([11,12,16]) = 7; t([5,6]) = 8;
members.sections = t;

sections.A = [0.94, 1.30, 1.38, 3.00, 3.71, 3.89, 4.72, 8.69]' * 1e-4;
sections.E = 206e9 * ones(8,1);

rvSpec.resGroup = t;
rvSpec.resMean  = ([25.944, 35.880, 38.088, 82.800, ...
                    102.396, 107.364, 130.272, 239.844] * 1e3)';
rvSpec.resStd   = rvSpec.resMean * 0.05;

l3.x.nodes = 3; l3.x.value = 1; l3.z.nodes = []; l3.z.value = [];
l5.x.nodes = 5; l5.x.value = 1; l5.z.nodes = []; l5.z.value = [];
l7.x.nodes = 7; l7.x.value = 1; l7.z.nodes = []; l7.z.value = [];
rvSpec.loadCases = {l3, l5, l7};
rvSpec.loadMean  = [44.45; 44.45; 44.45] * 1e3;
rvSpec.loadStd   = rvSpec.loadMean * 0.1;

opts = struct('eta', 0, 'rho0', 0.7, 'verbose', false);

%% how much of this example is in the QMC regime?
A_eq = equilibriumMatrixFn(nodes, members, kinematic);
[cs, gH, ~] = nullSpaceCutSetsFn(A_eq);
szs = cellfun(@numel, cs);
fprintf('gH = %d, cut-sets = %d, size distribution %s\n', ...
        gH, numel(cs), mat2str(histcounts(szs, 0.5:1:(gH+1.5))));
fprintf('cut-sets with m >= 4 (mvncdf QMC regime): %d\n\n', sum(szs >= 4));

%% seed sweep
REF = 3.001162;
seeds = [0 1 2 3 7 42 123 999 2026 31337];
B = zeros(size(seeds));
fprintf('%8s %14s %12s\n', 'seed', 'beta_sys', 'dev vs ref');
for i = 1:numel(seeds)
    rng(seeds(i));
    R = systemReliabilityFn(nodes, members, kinematic, sections, rvSpec, opts);
    B(i) = R.beta_sys;
    fprintf('%8d %14.6f %11.5f %%\n', seeds(i), B(i), 100*abs(B(i)-REF)/REF);
end

fprintf('\nmin %.6f  max %.6f  spread %.2e (%.4f %% of mean)\n', ...
        min(B), max(B), max(B)-min(B), 100*(max(B)-min(B))/mean(B));
fprintf('reference (Wei & Deng own method) = %.6f\n', REF);

if (max(B) - min(B)) < 1e-4
    fprintf('\nPASS: stable across seeds -- valid gate for the gradient fix.\n');
    fprintf('      after the fix, beta_sys must stay at %.5f +/- 1e-4\n', mean(B));
else
    fprintf('\n*** UNSTABLE across seeds -- this gate cannot be used as stated.\n');
end
