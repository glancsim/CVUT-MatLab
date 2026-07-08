% example_warren_xbrace.m
%
% Demonstration example (NOT a regression test -- no "right answer"):
% single-span, simply-supported Warren-style truss with FULL X-bracing in
% every panel (both diagonals present per panel, same redundant-bracing
% idea as the 3-story truss of example_3story_truss.m, but laid out as a
% horizontal roof/bridge truss with pin-roller supports instead of a
% cantilevered, both-ends-pinned tower).
%
% GEOMETRY: 3 panels, 4 m each (12 m span), 2 m height. Bottom chord nodes
% 1-4 at z=0, top chord nodes 5-8 directly above at z=2m. Members per
% panel: bottom chord, top chord, vertical, AND both diagonals (X-brace)
% -> statically indeterminate (gH=3 for this layout, verified below).
%
% BOUNDARY CONDITIONS: node 1 = pin (x AND z fixed), node 4 (bottom-right)
% = roller (z fixed only) -- standard simply-supported truss, unlike the
% 3-story truss's both-pinned cantilever-tower supports.
%
% LOADS: 2 independent downward point loads at the top-chord interior
% nodes (6, 7), Gaussian, mean=50 kN, COV=0.15 -- same order of magnitude
% as example_3story_truss's loads (44.45 kN), a plausible roof/floor point
% load.
%
% RESISTANCES: 4 illustrative section/role groups (bottom chord, top
% chord, verticals, diagonals -- diagonals in both directions share ONE
% group since a symmetric X-brace panel has no preferred diagonal
% direction), Gaussian, COV=0.08 (same COV(R) order as the 3-story
% truss's 0.05-COV groups, slightly larger to reflect a less-refined,
% illustrative section choice here). Mean resistances chosen loosely so
% chords/diagonals are comparably utilized under the applied loads (not
% independently fabrication-checked -- this is a worked demonstration,
% not a real design).
%
% RUNTIME NOTE: an earlier 4-panel version of this truss (21 members) was
% tried first and produced 153 cut-sets, 25 of them of size gH+1=5 (max
% permutation count 5!=120 each) -- combined with mostProbableSequenceFn's
% brute-force permutation search this made the full systemReliabilityFn
% call impractically slow (>15 minutes, killed before completion). The
% 3-panel version below (16 members, gH=3, 91 cut-sets, max size 4,
% 4!=24 perms) profiles at roughly 3 minutes total and was used instead --
% documented here since it's a real, reproducible cost of the brute-force
% mostProbableSequenceFn approach (see that function's own header note on
% scaling) rather than a bug.
%
% (c) S. Glanc, 2026

clear; close all;
srcDir  = fullfile(fileparts(mfilename('fullpath')), '..', 'src');
testDir = fullfile(fileparts(mfilename('fullpath')), '..', 'tests');
femDir  = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'fem-2d-truss-matlab', 'src');
addpath(srcDir); addpath(testDir); addpath(femDir);

%% Geometry
nPanels = 3;
Lpanel  = 4;    % m
H       = 2;    % m

nBot = nPanels + 1;                    % 4 bottom nodes
xBot = (0:nPanels)' * Lpanel;
zBot = zeros(nBot, 1);
xTop = xBot;
zTop = H * ones(nBot, 1);

nodes.x = [xBot; xTop];
nodes.z = [zBot; zTop];

nBotNodes = 1:nBot;
nTopNodes = (nBot+1):(2*nBot);

bc_head = nBotNodes(1:end-1)'; bc_end = nBotNodes(2:end)';       % bottom chord
tc_head = nTopNodes(1:end-1)'; tc_end = nTopNodes(2:end)';       % top chord
vert_head = nBotNodes';        vert_end = nTopNodes';            % verticals
diag1_head = nBotNodes(1:end-1)'; diag1_end = nTopNodes(2:end)';     % ascending diagonal
diag2_head = nBotNodes(2:end)';   diag2_end = nTopNodes(1:end-1)';   % descending diagonal (X-brace)

members.nodesHead = [bc_head; tc_head; vert_head; diag1_head; diag2_head];
members.nodesEnd  = [bc_end; tc_end; vert_end; diag1_end; diag2_end];
members.nmembers  = numel(members.nodesHead);
nm = members.nmembers;

% Section/resistance role: 1=bottom chord, 2=top chord, 3=vertical, 4=diagonal (both directions)
role = zeros(nm, 1);
idx = 1;
nBC = numel(bc_head);    role(idx:idx+nBC-1) = 1; idx = idx + nBC;
nTC = numel(tc_head);    role(idx:idx+nTC-1) = 2; idx = idx + nTC;
nV  = numel(vert_head);  role(idx:idx+nV-1)  = 3; idx = idx + nV;
nD1 = numel(diag1_head); role(idx:idx+nD1-1) = 4; idx = idx + nD1;
nD2 = numel(diag2_head); role(idx:idx+nD2-1) = 4; idx = idx + nD2;
members.sections = role;

sections.A = [20e-4; 20e-4; 8e-4; 6e-4];   % m^2: [bottom, top, vertical, diagonal]
sections.E = 210e9 * ones(4, 1);           % Pa, steel

% Boundary conditions: pin (node 1) + roller (node nBot=4)
kinematic.x.nodes = [1];
kinematic.z.nodes = [1; nBot];

fprintf('=== Warren X-brace truss demo (simply-supported, %d panels) ===\n', nPanels);
fprintf('nmembers = %d, nnodes = %d\n', nm, numel(nodes.x));

%% Confirm indeterminacy
A_eq = equilibriumMatrixFn(nodes, members, kinematic);
[cutSetsCheck, gH, ~] = nullSpaceCutSetsFn(A_eq);
fprintf('gH = %d, minimal cut-sets = %d\n', gH, numel(cutSetsCheck));

%% Random variable spec
rvSpec.resGroup = role;
rvSpec.resMean  = [300; 300; 150; 120] * 1e3;   % N: [bottom, top, vertical, diagonal]
rvSpec.resStd   = rvSpec.resMean * 0.08;        % COV(R) = 0.08

topLoadNodes = nTopNodes(2:end-1)';    % interior top-chord nodes (6, 7)
loads_p6.x.nodes = []; loads_p6.x.value = [];
loads_p6.z.nodes = topLoadNodes(1); loads_p6.z.value = -1;
loads_p7.x.nodes = []; loads_p7.x.value = [];
loads_p7.z.nodes = topLoadNodes(2); loads_p7.z.value = -1;

% Load level tuned so the MC oracle (modest 2e4 samples) actually observes
% a handful of failures: a first trial at 50 kN gave beta_sys=5.26 (0/2e4
% MC failures -- correct but uninformative, Pf~7e-8 needs far more samples
% than practical here); 95 kN gave beta_sys=0.53 (an unrealistically
% unsafe structure, just to prove the MC path works). 75 kN lands in a
% realistic "somewhat under-designed but not absurd" range with enough MC
% failures (~1-2%) for a meaningful beta_MC comparison at 2e4 samples.
rvSpec.loadCases = {loads_p6, loads_p7};
rvSpec.loadMean  = [75; 75] * 1e3;      % N, mean 75 kN each
rvSpec.loadStd   = rvSpec.loadMean * 0.15;

%% System reliability (Phase C, analytical PNET)
opts.eta     = 0;
opts.rho0    = 0.7;
opts.verbose = true;

tic;
results = systemReliabilityFn(nodes, members, kinematic, sections, rvSpec, opts);
t_analytical = toc;

fprintf('\n=== systemReliabilityFn result ===\n');
fprintf('beta_sys = %.4f   Pf_sys = %.4e   (elapsed %.1f s)\n', results.beta_sys, results.Pf_sys, t_analytical);
fprintf('finite and sensible: %d\n', isfinite(results.beta_sys) && isreal(results.beta_sys));

%% Independent cross-check: progressive-collapse Monte Carlo
mcOpts.verbose = true;
mcOpts.seed = 7;
[beta_MC, mcResults] = progressiveCollapseMCFn(nodes, members, kinematic, sections, rvSpec, 2e4, mcOpts);

fprintf('\n=== progressiveCollapseMCFn cross-check ===\n');
fprintf('beta_MC = %.4f  (analytical: %.4f)\n', beta_MC, results.beta_sys);

fprintf('\n=== SUMMARY ===\n');
fprintf('Demonstration example ran end-to-end: beta_sys=%.4f (analytical), beta_MC=%.4f (MC, %d samples, %d failures)\n', ...
    results.beta_sys, beta_MC, mcResults.nSamples, mcResults.nFail);
