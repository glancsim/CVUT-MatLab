% resistance_model_compare.m
%
% Robustness check for the NNM 2026 / Acta Polytechnica paper
% (`ctu-nnm-2026/RESISTANCE_MODEL_BRIEF.md`): does the reported
% beta_sys < beta_min effect survive when every member gets its OWN
% resistance random variable instead of sharing one per section group?
%
% The published model has 16 members drawing on 4 resistance RVs (one per
% section group), so e.g. all six diagonals are identically strong in any
% given sample. This script runs the whole analytical pipeline twice --
% once with that grouped rvSpec, once with a per-member rvSpec -- under
% identical seeds, and prints every quantity of brief section 3 side by side.
%
% WHAT CHANGES BETWEEN THE TWO VARIANTS: only rvSpec.resGroup/resMean/resStd.
% `members.sections` is untouched, so the AREAS stay grouped and the truss is
% physically the same structure, sized identically by the same FSD run. That
% invariance is asserted, not assumed: the FSD areas and every component
% beta_i must come out bit-identical, and the script errors out if they do
% not (a moved beta_min would mean the setup, not the physics, had changed).
%
% The grouped variant is recomputed here rather than transcribed from
% examples/warren_xbrace_paper_results.mat, so both columns of the table come
% from one run on one machine. The published .mat is still loaded, purely to
% assert that this machine reproduces beta_sys = 3.690481 exactly before any
% comparison is drawn from it.
%
% SEEDING: cornellIndexFn reaches mvncdf's randomised-QMC path for cut-sets
% of four or more members, so systemReliabilityFn is not deterministic (see
% cornellIndexFn's header). rng(42) is set before every headline and every
% sweep point, exactly as example_warren_xbrace_paper.m does; section 8
% varies the seed on purpose to measure that scatter for both variants.
%
% RUNTIME: 52 full systemReliabilityFn calls (2 headline + 2x5 sweep +
% 2x20 seeds), measured at 11-13 s each -> about 11 minutes. The per-member
% variant is only ~1.1x slower despite tripling the length of the U vector
% from 6 to 18, because equivalentPlaneFn's 2n finite-difference calls to
% cornellIndexFn are cheap next to the FEM solves in mostProbableSequenceFn.
%
% OUTPUT: prints to stdout; saves everything to resistance_model_compare.mat
% next to this file. The Monte Carlo half of the job is resistance_model_mc.m.
%
% See also: warrenXbraceModelFn, systemReliabilityFn, componentReliabilityFn,
%           resistance_model_mc, examples/example_warren_xbrace_paper
%
% (c) S. Glanc, 2026

clear;

thisDir = fileparts(mfilename('fullpath'));
root    = fullfile(thisDir, '..', '..', '..', '..');      % C:\GitHub\MatLab
exDir   = fullfile(root, 'system-reliability-truss-matlab', 'examples');
addpath(fullfile(root, 'system-reliability-truss-matlab', 'src'));
addpath(fullfile(root, 'system-reliability-truss-matlab', 'tests'));
addpath(exDir);
addpath(fullfile(root, 'fem-2d-truss-matlab', 'src'));

SEED      = 42;
RHO0      = 0.7;
RHO0SWEEP = [0.3 0.5 0.7 0.9 0.95];
NSEEDS    = 20;
NCORR     = 8;         % leading cut-sets / representatives in the corr. stats
TARGETCS  = [11 14];   % the cut-set whose beta_p equals beta_min when grouped

opts.eta = 0; opts.rho0 = RHO0; opts.verbose = false;

tStart = tic;

fprintf('==============================================================\n');
fprintf(' Resistance model: grouped (4 RVs) vs per-member (16 RVs)\n');
fprintf(' seed %d, rho0 %.2f, eta %g   --   MATLAB %s\n', SEED, RHO0, opts.eta, version);
fprintf('==============================================================\n');

%% 0. Model and the two rvSpec variants ----------------------------------
model     = warrenXbraceModelFn(struct('verbose', false));
nodes     = model.nodes;
members   = model.members;
kinematic = model.kinematic;
sections  = model.sections;
role      = model.role;
nm        = members.nmembers;

rv{1} = model.rvSpec;                              % as published
rv{2} = model.rvSpec;
rv{2}.resGroup = (1:nm)';
rv{2}.resMean  = model.f_y * sections.A(role);     % 16 values, expanded by role
rv{2}.resStd   = rv{2}.resMean * 0.08;

name = {'grouped (4 RV)', 'per-member (16 RV)'};

% --- the invariance the brief demands: same structure, same sizing --------
areasExp = [7.79481; 6.49091; 1.48074; 4.67493];   % cm^2
areasGot = sections.A(:) * 1e4;
if max(abs(areasGot - areasExp) ./ areasExp) > 1e-5
    error('resistance_model_compare:areaMismatch', ...
        'FSD areas %s do not match the published %s.', ...
        mat2str(areasGot', 6), mat2str(areasExp', 6));
end
if ~isequal(members.sections, role)
    error('resistance_model_compare:sectionsChanged', ...
        'members.sections must not change between the variants.');
end
% Same physical mean/std resistance for every member, just carried by a
% different number of RVs -- if this fails the two models are not comparable.
if ~isequal(rv{1}.resMean(rv{1}.resGroup), rv{2}.resMean(rv{2}.resGroup)) || ...
   ~isequal(rv{1}.resStd(rv{1}.resGroup),  rv{2}.resStd(rv{2}.resGroup))
    error('resistance_model_compare:momentMismatch', ...
        'Per-member resMean/resStd do not expand to the grouped values.');
end

fprintf('\nareas [cm^2]        = %s   (unchanged, asserted)\n', mat2str(areasGot', 6));
fprintf('resistance RVs      = %d (grouped) vs %d (per-member)\n', ...
    numel(rv{1}.resMean), numel(rv{2}.resMean));
fprintf('U vector length nU  = %d vs %d\n', ...
    numel(rv{1}.resMean) + numel(rv{1}.loadCases), ...
    numel(rv{2}.resMean) + numel(rv{2}.loadCases));

%% 1. Component reliability -- must be identical --------------------------
fprintf('\n--- 1. Component reliability (must be invariant) ---\n');
for v = 1:2
    comp{v}     = componentReliabilityFn(nodes, members, kinematic, sections, rv{v}); %#ok<SAGROW>
    [bmin, im]  = min(comp{v}.beta);
    beta_min(v) = bmin;         %#ok<SAGROW>
    Pf_min(v)   = comp{v}.Pf(im); %#ok<SAGROW>
    memberMin(v)= im;           %#ok<SAGROW>
    fprintf('%-20s beta_min = %.6f (member %2d)   Pf_min = %.8e\n', ...
        name{v}, beta_min(v), memberMin(v), Pf_min(v));
end
dComp = max(abs(comp{1}.beta - comp{2}.beta));
fprintf('max |beta_i(grouped) - beta_i(per-member)| = %.3e\n', dComp);
if dComp > 1e-12 || abs(beta_min(2) - 3.909383) > 1e-5
    error('resistance_model_compare:betaMinMoved', ...
        ['Component reliability is not invariant (max diff %.3e, beta_min %.6f).\n' ...
         'Brief section 2: if beta_min moves, the setup is wrong -- stop and report.'], ...
        dComp, beta_min(2));
end
fprintf('INVARIANCE OK -- the component estimate is fixed, so any change in\n');
fprintf('the gap below is entirely on the system side.\n');

%% 2. Headline system reliability -----------------------------------------
fprintf('\n--- 2. System reliability (seed %d, rho0 %.2f) ---\n', SEED, RHO0);
for v = 1:2
    rng(SEED); t = tic;
    res{v} = systemReliabilityFn(nodes, members, kinematic, sections, rv{v}, opts); %#ok<SAGROW>
    tCall(v) = toc(t); %#ok<SAGROW>
    ratio(v) = res{v}.Pf_sys / Pf_min(v); %#ok<SAGROW>
    nGrp(v)  = numel(res{v}.pnetGroups);  %#ok<SAGROW>
    fprintf('%-20s beta_sys = %.6f  Pf_sys = %.8e  ratio = %.4f  groups = %2d  (%.1f s)\n', ...
        name{v}, res{v}.beta_sys, res{v}.Pf_sys, ratio(v), nGrp(v), tCall(v));
    fprintf('%-20s beta_sys - beta_min = %+.6f\n', '', res{v}.beta_sys - beta_min(v));
end

% Does this machine reproduce the published grouped numbers?
pubMat = fullfile(exDir, 'warren_xbrace_paper_results.mat');
published = [];
if isfile(pubMat)
    P = load(pubMat, 'paper');
    published = P.paper;
    fprintf('\npublished grouped beta_sys = %.6f, this run = %.6f, diff = %.2e\n', ...
        published.beta_sys, res{1}.beta_sys, res{1}.beta_sys - published.beta_sys);
    if abs(res{1}.beta_sys - published.beta_sys) > 1e-6
        warning('resistance_model_compare:noRepro', ...
            ['This machine does not reproduce the published grouped beta_sys. ' ...
             'The per-member comparison is still internally consistent, but ' ...
             'the grouped column is not the number the paper quotes.']);
    end
else
    fprintf('\n(examples/warren_xbrace_paper_results.mat not found -- no cross-check)\n');
end

%% 3. Cut-sets -- topology is untouched, so these must be unchanged -------
fprintf('\n--- 3. Cut-sets (topology untouched) ---\n');
for v = 1:2
    sz{v} = cellfun(@numel, res{v}.cutSets); %#ok<SAGROW>
    u = unique(sz{v}(:))';
    fprintf('%-20s gH = %d, %d cut-sets, sizes:', name{v}, res{v}.gH, numel(res{v}.cutSets));
    for s = u, fprintf('  %dx size %d', sum(sz{v} == s), s); end
    fprintf('\n');
end
sameCutSets = isequal(res{1}.cutSets, res{2}.cutSets);
fprintf('cut-set LIST identical (same sets, same order): %d\n', sameCutSets);

%% 4-5. Correlation among leading cut-sets and representatives -----------
% Same construction as make_paper_figures' fig_cutset_correlation: the
% equivalent planes are unit-norm, so alphaTilde*alphaTilde' IS the
% correlation matrix; symmetrise and force the diagonal to 1 (the rows are
% unit-norm only to floating-point accuracy).
fprintf('\n--- 4/5. Correlation among the %d leading planes ---\n', NCORR);
fprintf('%-20s %-16s %8s %8s %8s %8s\n', 'variant', 'set', ['n>=' num2str(RHO0)], 'min', 'max', 'mean');
for v = 1:2
    [~, ordC] = sort(res{v}.betaTilde, 'ascend');
    selC      = ordC(1:NCORR);
    [~, gOrd] = sort([res{v}.pnetGroups.beta], 'ascend');
    selG      = arrayfun(@(g) g.repIdx, res{v}.pnetGroups(gOrd));
    selG      = selG(1:min(NCORR, numel(selG)));

    corrCut{v} = corrOfFn(res{v}.alphaTilde, selC); %#ok<SAGROW>
    corrRep{v} = corrOfFn(res{v}.alphaTilde, selG); %#ok<SAGROW>
    selCut{v}  = selC; selRep{v} = selG;            %#ok<SAGROW>

    statCut(v) = corrStatFn(corrCut{v}, RHO0); %#ok<SAGROW>
    statRep(v) = corrStatFn(corrRep{v}, RHO0); %#ok<SAGROW>
    printStatFn(name{v}, 'cut-sets',        statCut(v));
    printStatFn('',      'representatives', statRep(v));
    fprintf('%-20s leading cut-sets: %s\n', '', ...
        strjoin(cellfun(@(c) mat2str(c), res{v}.cutSets(selC)', 'UniformOutput', false), ' '));
end

%% 6. beta_p of the {11,14} cut-set against beta_min ----------------------
fprintf('\n--- 6. beta_p(%s) vs beta_min ---\n', mat2str(TARGETCS));
for v = 1:2
    ci = find(cellfun(@(c) isequal(sort(c(:))', TARGETCS), res{v}.cutSets), 1);
    if isempty(ci)
        fprintf('%-20s cut-set %s not found\n', name{v}, mat2str(TARGETCS));
        betaTarget(v) = NaN; dTarget(v) = NaN; %#ok<SAGROW>
        continue;
    end
    targetIdx(v)  = ci;                       %#ok<SAGROW>
    betaTarget(v) = res{v}.betaPerCutSet(ci); %#ok<SAGROW>
    dTarget(v)    = betaTarget(v) - beta_min(v); %#ok<SAGROW>
    isWorst       = betaTarget(v) <= min(res{v}.betaPerCutSet) + 1e-12;
    fprintf('%-20s beta_p = %.10f   beta_min = %.10f   diff = %+.3e   worst cut-set: %d\n', ...
        name{v}, betaTarget(v), beta_min(v), dTarget(v), isWorst);
    [bw, iw] = min(res{v}.betaPerCutSet);
    fprintf('%-20s   worst cut-set is %s at beta_p = %.6f\n', '', ...
        mat2str(res{v}.cutSets{iw}), bw);
end

%% 7. rho0 sweep ----------------------------------------------------------
fprintf('\n--- 7. rho0 sweep (rng(%d) re-set before EVERY point) ---\n', SEED);
fprintf('%8s | %26s | %26s\n', '', name{1}, name{2});
fprintf('%8s | %10s %8s %6s | %10s %8s %6s\n', 'rho0', ...
    'beta_sys', 'ratio', 'grp', 'beta_sys', 'ratio', 'grp');
nSw = numel(RHO0SWEEP);
sweepBeta = zeros(nSw, 2); sweepPf = zeros(nSw, 2);
sweepRatio = zeros(nSw, 2); sweepGrp = zeros(nSw, 2);
for k = 1:nSw
    o = opts; o.rho0 = RHO0SWEEP(k);
    for v = 1:2
        rng(SEED);
        r = systemReliabilityFn(nodes, members, kinematic, sections, rv{v}, o);
        sweepBeta(k, v)  = r.beta_sys;
        sweepPf(k, v)    = r.Pf_sys;
        sweepRatio(k, v) = r.Pf_sys / Pf_min(v);
        sweepGrp(k, v)   = numel(r.pnetGroups);
    end
    fprintf('%8.2f | %10.4f %8.4f %6d | %10.4f %8.4f %6d\n', RHO0SWEEP(k), ...
        sweepBeta(k,1), sweepRatio(k,1), sweepGrp(k,1), ...
        sweepBeta(k,2), sweepRatio(k,2), sweepGrp(k,2));
end

%% 8. QMC seed scatter ----------------------------------------------------
fprintf('\n--- 8. QMC noise: %d seeds, identical inputs ---\n', NSEEDS);
betaSeeds = zeros(NSEEDS, 2); PfSeeds = zeros(NSEEDS, 2); grpSeeds = zeros(NSEEDS, 2);
for s = 1:NSEEDS
    for v = 1:2
        rng(s);
        r = systemReliabilityFn(nodes, members, kinematic, sections, rv{v}, opts);
        betaSeeds(s, v) = r.beta_sys;
        PfSeeds(s, v)   = r.Pf_sys;
        grpSeeds(s, v)  = numel(r.pnetGroups);
    end
    fprintf('  seed %2d: %.6f (%2d grp) | %.6f (%2d grp)\n', s, ...
        betaSeeds(s,1), grpSeeds(s,1), betaSeeds(s,2), grpSeeds(s,2));
end
for v = 1:2
    fprintf('%-20s beta_sys over %d seeds: mean %.6f  std %.6f  range [%.6f, %.6f]  groups %d..%d\n', ...
        name{v}, NSEEDS, mean(betaSeeds(:,v)), std(betaSeeds(:,v)), ...
        min(betaSeeds(:,v)), max(betaSeeds(:,v)), min(grpSeeds(:,v)), max(grpSeeds(:,v)));
    fprintf('%-20s   distinct values (1e-6 tol): %d\n', '', ...
        numel(uniquetol(betaSeeds(:,v), 1e-6, 'DataScale', 1)));
end

%% 9. Verdict -------------------------------------------------------------
fprintf('\n--- 9. Verdict (brief section 5) ---\n');
for v = 1:2
    fprintf('%-20s beta_sys %.6f  %s  beta_min %.6f   (Pf ratio %.4f)\n', name{v}, ...
        res{v}.beta_sys, ternFn(res{v}.beta_sys < beta_min(v), '<', '>='), ...
        beta_min(v), ratio(v));
end
if res{2}.beta_sys < beta_min(2)
    if ratio(2) >= ratio(1)
        fprintf('EFFECT SURVIVES AND STRENGTHENS: ratio %.4f -> %.4f (x%.3f)\n', ...
            ratio(1), ratio(2), ratio(2)/ratio(1));
    else
        fprintf('EFFECT WEAKENS BUT SURVIVES: ratio %.4f -> %.4f (x%.3f)\n', ...
            ratio(1), ratio(2), ratio(2)/ratio(1));
    end
else
    fprintf('EFFECT DISAPPEARS under per-member resistances.\n');
end

%% Save -------------------------------------------------------------------
cmp = struct('seed', SEED, 'rho0', RHO0, 'nCorr', NCORR, 'name', {name}, ...
    'areas_cm2', areasGot', 'beta_comp', [comp{1}.beta, comp{2}.beta], ...
    'beta_min', beta_min, 'Pf_min', Pf_min, 'memberMin', memberMin, ...
    'beta_sys', [res{1}.beta_sys, res{2}.beta_sys], ...
    'Pf_sys', [res{1}.Pf_sys, res{2}.Pf_sys], 'ratio', ratio, 'nGroups', nGrp, ...
    'callTime', tCall, 'cutSetSizes', {sz}, 'sameCutSets', sameCutSets, ...
    'corrCut', {corrCut}, 'corrRep', {corrRep}, 'selCut', {selCut}, 'selRep', {selRep}, ...
    'statCut', statCut, 'statRep', statRep, ...
    'betaTarget', betaTarget, 'dTarget', dTarget, 'targetCutSet', TARGETCS, ...
    'rho0Sweep', RHO0SWEEP, 'sweepBeta', sweepBeta, 'sweepPf', sweepPf, ...
    'sweepRatio', sweepRatio, 'sweepGroups', sweepGrp, ...
    'betaSeeds', betaSeeds, 'PfSeeds', PfSeeds, 'groupSeeds', grpSeeds, ...
    'published', published, 'matlabVersion', version);

outMat = fullfile(thisDir, 'resistance_model_compare.mat');
save(outMat, 'cmp', 'res', 'rv', 'model');
fprintf('\nsaved -> %s\n', outMat);
fprintf('total elapsed: %.1f min\n', toc(tStart)/60);

%% ------------------------------------------------------------------------
function R = corrOfFn(alphaTilde, sel)
n = numel(sel);
R = alphaTilde(sel, :) * alphaTilde(sel, :)';
R = (R + R') / 2;
R(1:n+1:end) = 1;
end

function s = corrStatFn(R, rho0)
msk = triu(true(size(R, 1)), 1);
v = R(msk);
s = struct('n', sum(v >= rho0), 'nPairs', numel(v), 'min', min(v), ...
    'max', max(v), 'mean', mean(v));
end

function printStatFn(variant, what, s)
fprintf('%-20s %-16s %4d/%-3d %8.3f %8.3f %8.3f\n', variant, what, ...
    s.n, s.nPairs, s.min, s.max, s.mean);
end

function out = ternFn(c, a, b)
if c, out = a; else, out = b; end
end
