% example_warren_xbrace.m
%
% Demonstration example (NOT a regression test -- no "right answer"):
% single-span, simply-supported Warren-style truss with FULL X-bracing in
% every panel (both diagonals present per panel, same redundant-bracing
% idea as the 3-story truss of example_3story_truss.m, but laid out as a
% horizontal roof/bridge truss with pin-roller supports instead of a
% cantilevered, both-ends-pinned tower).
%
% The model itself (geometry, BCs, RV spec, FSD sizing) lives in
% warrenXbraceModelFn.m, shared with example_warren_xbrace_paper.m and
% make_paper_figures.m; this script is the interactive walk-through of it.
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
% nodes (6, 7), Gaussian, mean=75 kN, COV=0.15 -- the same order of
% magnitude as example_3story_truss's loads (44.45 kN), a plausible
% roof/floor point load. See warrenXbraceModelFn.m for why 75 kN and not
% the 50 kN of the first trial.
%
% RESISTANCES: 4 section/role groups (bottom chord, top chord, verticals,
% diagonals -- diagonals in both directions share ONE group since a
% symmetric X-brace panel has no preferred diagonal direction). Areas are
% NOT chosen by hand: fullyStressedDesignFn.m iteratively sizes each group
% (stress-ratio / FSD method) so its governing member reaches
% sigmaAllow=210 MPa under the mean combined load -- a simple gross-stress
% criterion (no buckling check, unlike en-truss-design-matlab), consistent
% with this being a worked demonstration, not a code-compliant design.
% rvSpec.resMean is then set to f_y*A (S355, f_y=355 MPa) for the
% converged A of each group -- i.e. 210 MPa is treated as an implicit ASD
% allowable stress (f_y/210 ~= 1.69, a plausible safety factor), giving a
% real (non-degenerate) margin instead of resMean==sizing-stress*A, which
% would force beta~=0 for every governing member by construction.
% Gaussian, COV(R)=0.08 (same order as the 3-story truss's 0.05-COV
% groups, slightly larger to reflect this simpler sizing method here).
%
% RUNTIME NOTE: an earlier 4-panel version of this truss (21 members) was
% tried first and produced 153 cut-sets, 25 of them of size gH+1=5 (max
% permutation count 5!=120 each) -- combined with mostProbableSequenceFn's
% brute-force permutation search this made the full systemReliabilityFn
% call impractically slow (>15 minutes, killed before completion). The
% 3-panel version used here (16 members, gH=3, 91 cut-sets, max size 4,
% 4!=24 perms) profiles at roughly 30 s for the systemReliabilityFn call
% and was used instead -- documented since it's a real, reproducible cost
% of the brute-force mostProbableSequenceFn approach (see that function's
% own header note on scaling) rather than a bug.
%
% (c) S. Glanc, 2026

clear; close all;
rng(42);   % QMC quadrature inside mvncdf (cornellIndexFn) is randomised;
           % fixed here so the published numbers are reproducible

exDir   = fileparts(mfilename('fullpath'));
srcDir  = fullfile(exDir, '..', 'src');
testDir = fullfile(exDir, '..', 'tests');
femDir  = fullfile(exDir, '..', '..', 'fem-2d-truss-matlab', 'src');
addpath(exDir); addpath(srcDir); addpath(testDir); addpath(femDir);

%% Model setup (geometry, topology, BCs, RV spec, FSD sizing)
model = warrenXbraceModelFn(struct('verbose', true));

nodes     = model.nodes;
members   = model.members;
kinematic = model.kinematic;
sections  = model.sections;
rvSpec    = model.rvSpec;
meanLoads = model.meanLoads;
role      = model.role;
roleNames = model.roleNames;

%% Visualize geometry, supports, and (mean) loads
plotTrussFn(nodes, members, meanLoads, kinematic, 'Labels', true);

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

%% Most critical failure sequences (PNET-dominant cut-sets, worst-first)
[~, pnetOrder] = sort([results.pnetGroups.beta], 'ascend');
nShow = min(10, numel(pnetOrder));

fprintf('\n=== Most critical failure sequences (%d/%d PNET-dominant cut-sets shown) ===\n', ...
    nShow, numel(results.pnetGroups));
fprintf('%6s  %-24s  %-24s  %10s\n', 'rank', 'cut-set', 'rep. sequence', 'beta_p');
for r = 1:nShow
    g = results.pnetGroups(pnetOrder(r));
    fprintf('%6d  %-24s  %-24s  %10.4f\n', r, mat2str(results.cutSets{g.repIdx}), ...
        mat2str(results.repSequence{g.repIdx}), g.beta);
end

%% Component reliability (per-member, intact structure, no redundancy credit)
compResults = componentReliabilityFn(nodes, members, kinematic, sections, rvSpec);

fprintf('\n=== componentReliabilityFn result (weakest-link-first) ===\n');
fprintf('%6s  %-14s  %8s  %12s\n', 'member', 'role', 'beta_i', 'Pf_i');
for k = 1:members.nmembers
    i = compResults.sortIdx(k);
    fprintf('%6d  %-14s  %8.4f  %12.4e\n', i, roleNames{role(i)}, compResults.beta(i), compResults.Pf(i));
end
beta_min = min(compResults.beta);
fprintf('\nweakest component: member %d, beta_min = %.4f (naive series-system estimate)\n', ...
    compResults.sortIdx(1), beta_min);
fprintf('beta_sys (system, redundancy credited) = %.4f  ->  redundancy gain = %.4f\n', ...
    results.beta_sys, results.beta_sys - beta_min);

% %% Independent cross-check: progressive-collapse Monte Carlo
% % NOTE: at 75 kN the system failure probability is Pf_sys ~ 1.1e-04
% % (0.011 %), so a 2e4-sample run expects ~2 failures -- far too few for a
% % meaningful beta_MC. A useful MC cross-check needs on the order of 1e7
% % samples; see tests/mc_neptun/ for that separate run.
% mcOpts.verbose = true;
% mcOpts.seed = 7;
% [beta_MC, mcResults] = progressiveCollapseMCFn(nodes, members, kinematic, sections, rvSpec, 2e4, mcOpts);
%
% fprintf('\n=== progressiveCollapseMCFn cross-check ===\n');
% fprintf('beta_MC = %.4f  (analytical: %.4f)\n', beta_MC, results.beta_sys);
%
% fprintf('\n=== SUMMARY ===\n');
% fprintf('Demonstration example ran end-to-end: beta_sys=%.4f (analytical), beta_MC=%.4f (MC, %d samples, %d failures)\n', ...
%     results.beta_sys, beta_MC, mcResults.nSamples, mcResults.nFail);
