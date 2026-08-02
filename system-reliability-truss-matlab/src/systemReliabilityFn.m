function results = systemReliabilityFn(nodes, members, kinematic, sections, rvSpec, opts)
% systemReliabilityFn  System reliability of a statically-indeterminate 2D
% pin-jointed truss via the null-space cut-set method + Cornell/PNET
% (metodika.md, Wei & Deng 2022). Orchestrates Phases A-C:
%
%   1. equilibriumMatrixFn + nullSpaceCutSetsFn -> all minimal cut-sets
%   2. mostProbableSequenceFn (per cut-set)     -> representative failure mode
%   3. equivalentPlaneFn (per representative)   -> (betaTilde_k, alphaTilde_k)
%   4. pnetSystemReliabilityFn                  -> beta_sys, Pf_sys
%
% Unlike reliability-truss-matlab/systemReliabilityFn (statically
% DETERMINATE trusses, g_sys = min_p g_p, series system, UQLab Monte
% Carlo) this module targets INDETERMINATE trusses where failure of one
% member redistributes load rather than immediately failing the system --
% the system limit state is a PNET combination of parallel-subsystem
% (failure-sequence) events, evaluated via first-order (Cornell) linear
% algebra, no sampling.
%
% INPUTS:
%   nodes, members, kinematic - truss geometry/topology/BCs, fem-2d-truss-
%       matlab convention (see equilibriumMatrixFn / linearSolverFn)
%   sections - (struct) .A, .E per section-index (linearSolverFn convention)
%   rvSpec   - (struct) random-variable spec, see sequenceLimitStateFn:
%       .resGroup, .resMean, .resStd, .loadCases, .loadMean, .loadStd
%   opts     - (struct, optional):
%       .eta       - ductile residual fraction (scalar or nmembers x 1),
%                    default 0 (brittle -- the ONLY case validated against
%                    a reference example, see metodika.md)
%       .rho0      - PNET correlation threshold, default 0.7
%       .verbose   - logical, default true
%
% OUTPUTS: results - (struct)
%       .beta_sys       - system reliability index
%       .Pf_sys         - system probability of failure
%       .cutSets        - cell array of minimal cut-sets (from Phase A)
%       .gH             - degree of static indeterminacy
%       .betaPerCutSet  - (q x 1) beta_p of the representative failure mode
%                          of each cut-set (BEFORE PNET grouping/linearization)
%       .betaTilde      - (q x 1) equivalent linear beta per cut-set
%       .alphaTilde     - (q x n) equivalent linear alpha per cut-set
%       .repSequence    - (1 x q) cell array, the best-ordering member
%                          sequence for each cut-set
%       .pnetGroups     - struct array from pnetSystemReliabilityFn
%
% REPRODUCIBILITY: this function is NOT deterministic -- cut-sets of four or
% more members reach cornellIndexFn's randomised-QMC mvncdf path (see that
% file's "NOT DETERMINISTIC FOR m >= 4" note for the measured scatter). Call
% rng(<seed>) beforehand if the output must be reproducible.
%
% See also: equilibriumMatrixFn, nullSpaceCutSetsFn, mostProbableSequenceFn,
%           equivalentPlaneFn, pnetSystemReliabilityFn, sequenceLimitStateFn
%
% (c) S. Glanc, 2026

if nargin < 6, opts = struct(); end
if ~isfield(opts, 'eta'),     opts.eta     = 0;    end
if ~isfield(opts, 'rho0'),    opts.rho0    = 0.7;  end
if ~isfield(opts, 'verbose'), opts.verbose = true; end

if opts.verbose, fprintf('=== systemReliabilityFn: null-space cut-set + PNET ===\n'); end

%% 1. Cut-sets
A = equilibriumMatrixFn(nodes, members, kinematic);
[cutSets, gH, ~] = nullSpaceCutSetsFn(A);
q = numel(cutSets);

if opts.verbose
    fprintf('  gH = %d, minimal cut-sets found = %d\n', gH, q);
end

if q == 0
    results.beta_sys = Inf;
    results.Pf_sys   = 0;
    results.cutSets  = cutSets;
    results.gH       = gH;
    results.betaPerCutSet = [];
    results.betaTilde     = [];
    results.alphaTilde    = [];
    results.repSequence   = {};
    results.pnetGroups    = struct('repIdx', {}, 'members', {}, 'beta', {});
    if opts.verbose, fprintf('  No cut-sets (gH=0 or fully determinate) -> beta_sys = Inf\n'); end
    return;
end

%% 2-3. Representative failure mode + equivalent plane per cut-set
betaPerCutSet = zeros(q, 1);
repSequence   = cell(1, q);
nU = numel(rvSpec.resMean) + numel(rvSpec.loadCases);
betaTilde  = zeros(q, 1);
alphaTilde = zeros(q, nU);

for c = 1:q
    [bestSeq, bestBetaP] = mostProbableSequenceFn(nodes, members, kinematic, ...
        sections, cutSets{c}, rvSpec, opts.eta);
    repSequence{c}     = bestSeq;
    betaPerCutSet(c)   = bestBetaP;

    seq = sequenceLimitStateFn(nodes, members, kinematic, sections, bestSeq, rvSpec, opts.eta);
    k = numel(seq);
    alpha = zeros(k, nU);
    betaVec = zeros(k, 1);
    for i = 1:k
        sd = sqrt(seq(i).varG);
        alpha(i, :) = -seq(i).coeffU / sd;
        betaVec(i)  = seq(i).meanG / sd;
    end
    [betaTilde(c), alphaTilde(c, :)] = equivalentPlaneFn(alpha, betaVec);

    if opts.verbose
        fprintf('  cut-set %2d/%2d %-18s beta_p = %.4f\n', c, q, mat2str(cutSets{c}), betaPerCutSet(c));
    end
end

%% 4. PNET combination
[beta_sys, Pf_sys, pnetGroups] = pnetSystemReliabilityFn(betaTilde, alphaTilde, opts.rho0);

if opts.verbose
    fprintf('  PNET groups (rho0=%.2f): %d representative(s) out of %d cut-sets\n', ...
        opts.rho0, numel(pnetGroups), q);
    fprintf('  beta_sys = %.4f   Pf_sys = %.4e\n', beta_sys, Pf_sys);
end

results.beta_sys      = beta_sys;
results.Pf_sys         = Pf_sys;
results.cutSets        = cutSets;
results.gH             = gH;
results.betaPerCutSet  = betaPerCutSet;
results.betaTilde      = betaTilde;
results.alphaTilde     = alphaTilde;
results.repSequence    = repSequence;
results.pnetGroups     = pnetGroups;

end
