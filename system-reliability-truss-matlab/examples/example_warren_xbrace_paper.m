% example_warren_xbrace_paper.m
%
% Regenerates EVERY number the NNM 2026 / Acta Polytechnica paper quotes for
% the Warren X-brace example, in one run, in the order the paper uses them.
% Companion to make_paper_figures.m (the figures) and example_warren_xbrace.m
% (the interactive walk-through); all three share warrenXbraceModelFn.m so
% the model is defined in exactly one place.
%
% SEEDING: cornellIndexFn evaluates mvncdf by randomised quasi-Monte Carlo
% for cut-sets of four or more members, so systemReliabilityFn is not
% deterministic (see cornellIndexFn.m's header). rng(42) is therefore set
% before EVERY systemReliabilityFn call in this script -- including each
% point of the rho0 sweep, so that the sweep shows the rho0 effect and not
% the seed noise. Section 6 deliberately does the opposite: it varies the
% seed on purpose to quantify how large that noise is.
%
% RUNTIME: dominated by 31 full systemReliabilityFn calls (1 headline + 20
% seeds + 10 rho0 points). Measured per-call cost on the development machine
% swung between 7.4 s and 26 s depending on the machine's power/thermal
% state, so budget anywhere from 4 minutes to half an hour; the run that
% produced the published numbers wall-clocked 134 minutes on a heavily
% throttled machine. This is expected; do not optimise it. In particular
% the rho0 sweep is NOT
% shortcut through pnetSystemReliabilityFn even though rho0 only enters the
% final PNET step -- re-running the whole pipeline under a fixed seed is
% what makes the sweep an honest sensitivity study rather than a claim the
% reader has to take on trust.
%
% OUTPUT: prints to stdout, and saves every quantity to
% examples/warren_xbrace_paper_results.mat for make_paper_figures.m to
% reuse (delete that file to force a recompute).
%
% See also: warrenXbraceModelFn, make_paper_figures, example_warren_xbrace
%
% (c) S. Glanc, 2026

clear; close all;

exDir   = fileparts(mfilename('fullpath'));
addpath(exDir);
addpath(fullfile(exDir, '..', 'src'));
addpath(fullfile(exDir, '..', 'tests'));
addpath(fullfile(exDir, '..', '..', 'fem-2d-truss-matlab', 'src'));

SEED      = 42;
RHO0      = 0.7;
RHO0SWEEP = [0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.95 0.98 0.999];
NSEEDS    = 20;
BANDWIDTH = 0.2;      % "within 0.2 of beta_min" band used in the paper

opts.eta     = 0;
opts.rho0    = RHO0;
opts.verbose = false;

tStart = tic;

model = warrenXbraceModelFn(struct('verbose', false));
nodes     = model.nodes;
members   = model.members;
kinematic = model.kinematic;
sections  = model.sections;
rvSpec    = model.rvSpec;

fprintf('==========================================================\n');
fprintf(' Warren X-brace -- all paper numbers   (seed %d, rho0 %.2f)\n', SEED, RHO0);
fprintf('==========================================================\n');
fprintf('nmembers = %d, nnodes = %d, gH = %d, minimal cut-sets = %d\n', ...
    members.nmembers, numel(nodes.x), model.gH, numel(model.cutSets));

%% 1. FSD converged areas ------------------------------------------------
fprintf('\n--- 1. Fully-stressed design (sigmaAllow = %.0f MPa) ---\n', model.sigmaAllow/1e6);
fprintf('%-16s %12s %14s\n', 'group', 'A [cm^2]', 'R_mean [kN]');
for g = 1:numel(model.roleNames)
    fprintf('%-16s %12.5f %14.1f\n', model.roleNames{g}, ...
        model.sections.A(g)*1e4, rvSpec.resMean(g)/1e3);
end
fprintf('areas [cm^2] = %s\n', sprintf('%.5f  ', model.sections.A*1e4));

%% 2. Component reliability ----------------------------------------------
comp = componentReliabilityFn(nodes, members, kinematic, sections, rvSpec);
[beta_min, iMin] = min(comp.beta);
Pf_min  = comp.Pf(iMin);
nInBand = sum(comp.beta <= beta_min + BANDWIDTH);
inBand  = comp.sortIdx(1:nInBand)';

fprintf('\n--- 2. Component reliability (intact structure) ---\n');
fprintf('%8s  %-14s %10s %16s\n', 'member', 'role', 'beta_i', 'Pf_i');
for k = 1:members.nmembers
    i = comp.sortIdx(k);
    fprintf('%8d  %-14s %10.4f %16.4e\n', i, model.roleNames{model.role(i)}, comp.beta(i), comp.Pf(i));
end
fprintf('beta_min = %.6f  (member %d)\n', beta_min, iMin);
fprintf('Pf_min   = %.8e\n', Pf_min);
fprintf('members within %.1f of beta_min: %d  ->  %s\n', BANDWIDTH, nInBand, mat2str(inBand));
fprintf('   groups spanned by those %d: %s\n', nInBand, ...
    strjoin(model.roleNames(unique(model.role(inBand))), ', '));

%% 3. System reliability at the paper's operating point ------------------
fprintf('\n--- 3. System reliability (seed %d, rho0 = %.2f) ---\n', SEED, RHO0);
rng(SEED);
tSys = tic;
res  = systemReliabilityFn(nodes, members, kinematic, sections, rvSpec, opts);
tSys = toc(tSys);
ratio = res.Pf_sys / Pf_min;

fprintf('beta_sys = %.6f\n', res.beta_sys);
fprintf('Pf_sys   = %.8e\n', res.Pf_sys);
fprintf('ratio Pf_sys/Pf_min = %.4f\n', ratio);
fprintf('PNET groups = %d  (out of %d cut-sets)\n', numel(res.pnetGroups), numel(res.cutSets));
fprintf('beta_sys - beta_min = %.6f   (elapsed %.1f s)\n', res.beta_sys - beta_min, tSys);

%% 4. Full PNET group listing --------------------------------------------
[~, gOrder] = sort([res.pnetGroups.beta], 'ascend');
Pf_g   = normcdf(-[res.pnetGroups.beta]);
sumPfg = sum(Pf_g);

fprintf('\n--- 4. PNET groups, worst first (rho0 = %.2f) ---\n', RHO0);
fprintf('%5s  %-18s %10s %16s %8s %10s\n', 'rank', 'cut-set', 'beta_p', 'Pf_p', 'nCutSet', 'share');
for r = 1:numel(gOrder)
    g = res.pnetGroups(gOrder(r));
    fprintf('%5d  %-18s %10.4f %16.4e %8d %10.4f\n', r, mat2str(res.cutSets{g.repIdx}), ...
        g.beta, normcdf(-g.beta), numel(g.members), normcdf(-g.beta)/sumPfg);
end
fprintf('sum of group Pf = %.6e   (Pf_sys = %.6e, union correction %.2e)\n', ...
    sumPfg, res.Pf_sys, sumPfg - res.Pf_sys);
fprintf('worst group share of summed Pf = %.4f\n', max(Pf_g)/sumPfg);

%% 5. Cut-set size histogram ---------------------------------------------
sz = cellfun(@numel, res.cutSets);
fprintf('\n--- 5. Cut-set size histogram ---\n');
for s = unique(sz(:))'
    fprintf('size %d: %3d cut-sets\n', s, sum(sz == s));
end
fprintf('total: %d\n', numel(sz));

%% 6. QMC noise over %d seeds --------------------------------------------
fprintf('\n--- 6. QMC noise: %d seeds, identical inputs (rho0 = %.2f) ---\n', NSEEDS, RHO0);
betaSeeds  = zeros(NSEEDS, 1);
PfSeeds    = zeros(NSEEDS, 1);
groupSeeds = zeros(NSEEDS, 1);
for s = 1:NSEEDS
    rng(s);
    r = systemReliabilityFn(nodes, members, kinematic, sections, rvSpec, opts);
    betaSeeds(s)  = r.beta_sys;
    PfSeeds(s)    = r.Pf_sys;
    groupSeeds(s) = numel(r.pnetGroups);
    fprintf('  seed %2d: beta_sys = %.6f  Pf_sys = %.4e  groups = %2d\n', s, r.beta_sys, r.Pf_sys, groupSeeds(s));
end
fprintf('beta_sys : mean %.6f  std %.6f  range [%.6f, %.6f]\n', ...
    mean(betaSeeds), std(betaSeeds), min(betaSeeds), max(betaSeeds));
fprintf('Pf_sys   : mean %.4e  std %.4e\n', mean(PfSeeds), std(PfSeeds));
fprintf('groups   : %d to %d\n', min(groupSeeds), max(groupSeeds));
fprintf('seed %d value (%.6f) lies %.2f std below the mean\n', ...
    SEED, res.beta_sys, (mean(betaSeeds) - res.beta_sys)/std(betaSeeds));

%% 7. rho0 sensitivity sweep ---------------------------------------------
fprintf('\n--- 7. rho0 sensitivity (rng(%d) re-set before EVERY point) ---\n', SEED);
nSw        = numel(RHO0SWEEP);
sweepBeta  = zeros(nSw, 1);
sweepPf    = zeros(nSw, 1);
sweepRatio = zeros(nSw, 1);
sweepGroup = zeros(nSw, 1);
fprintf('%8s %12s %16s %10s %8s\n', 'rho0', 'beta_sys', 'Pf_sys', 'ratio', 'groups');
for k = 1:nSw
    o = opts; o.rho0 = RHO0SWEEP(k);
    rng(SEED);
    r = systemReliabilityFn(nodes, members, kinematic, sections, rvSpec, o);
    sweepBeta(k)  = r.beta_sys;
    sweepPf(k)    = r.Pf_sys;
    sweepRatio(k) = r.Pf_sys / Pf_min;
    sweepGroup(k) = numel(r.pnetGroups);
    fprintf('%8.2f %12.4f %16.4e %10.4f %8d\n', RHO0SWEEP(k), sweepBeta(k), sweepPf(k), sweepRatio(k), sweepGroup(k));
end

%% 8. Lower-bound check ---------------------------------------------------
% Eq. (bound): the system can be no safer than its worst single failure
% path, so beta_sys <= min_p beta_p <= beta_min. The check below is the
% second inequality: the worst cut-set's equivalent beta_p must not exceed
% beta_min, and here it should coincide with it exactly, because the worst
% cut-set {11,14} fails through member 11 -- which is itself the weakest
% component -- so its first sequence element IS the component limit state.
[betaWorst, iWorst] = min([res.pnetGroups.beta]);
worstCutSet = res.cutSets{res.pnetGroups(iWorst).repIdx};
fprintf('\n--- 8. Lower-bound check ---\n');
fprintf('worst cut-set        : %s\n', mat2str(worstCutSet));
fprintf('beta_p(worst)        : %.10f\n', betaWorst);
fprintf('beta_min (member %2d) : %.10f\n', iMin, beta_min);
fprintf('beta_p(worst) - beta_min = %.3e\n', betaWorst - beta_min);
fprintf('beta_sys (%.6f) <= beta_min (%.6f): %d\n', res.beta_sys, beta_min, res.beta_sys <= beta_min);

%% Save -------------------------------------------------------------------
paper = struct( ...
    'seed', SEED, 'rho0', RHO0, 'bandWidth', BANDWIDTH, ...
    'areas_cm2', model.sections.A(:)'*1e4, ...
    'beta_comp', comp.beta, 'Pf_comp', comp.Pf, 'sortIdx', comp.sortIdx, ...
    'beta_min', beta_min, 'Pf_min', Pf_min, 'memberMin', iMin, ...
    'nInBand', nInBand, 'inBand', inBand, ...
    'beta_sys', res.beta_sys, 'Pf_sys', res.Pf_sys, 'ratio', ratio, ...
    'nGroups', numel(res.pnetGroups), 'cutSetSizes', sz(:)', ...
    'groupOrder', gOrder(:)', 'groupPf', Pf_g(:)', 'sumGroupPf', sumPfg, ...
    'betaSeeds', betaSeeds, 'PfSeeds', PfSeeds, 'groupSeeds', groupSeeds, ...
    'rho0Sweep', RHO0SWEEP(:)', 'sweepBeta', sweepBeta(:)', 'sweepPf', sweepPf(:)', ...
    'sweepRatio', sweepRatio(:)', 'sweepGroups', sweepGroup(:)', ...
    'worstCutSet', worstCutSet, 'betaWorst', betaWorst);

outMat = fullfile(exDir, 'warren_xbrace_paper_results.mat');
save(outMat, 'paper', 'model', 'comp', 'res');
fprintf('\nsaved -> %s\n', outMat);
fprintf('total elapsed: %.1f min\n', toc(tStart)/60);
