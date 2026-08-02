function out = resistance_model_mc(opts)
% resistance_model_mc  Monte Carlo half of the resistance-model robustness
% check (`ctu-nnm-2026/RESISTANCE_MODEL_BRIEF.md` section 4).
%
% Runs the approximation-free progressive-collapse oracle on BOTH resistance
% models -- the published grouped one (16 members, 4 resistance RVs) and the
% per-member one (16 RVs) -- at the same sample count and the same chunk
% seeds, so the two Monte Carlo estimates are directly comparable. The brief
% only asks for the per-member run; the grouped run is included because the
% published grouped estimate comes from 1e8 samples on neptun, and comparing
% a fresh 1e6 against it would confound the model change with the sampling
% precision. Both are reported.
%
% Reuses tests/mc_neptun/mcRunChunk.m unmodified, hence the identical
% chunking, sub-batching and one-seed-per-chunk contract as the published
% run (see tests/mc_neptun/README.md "Design notes"). It does NOT reuse
% runMcNeptun, which hard-wires mcNeptunSetup's grouped rvSpec.
%
% The model comes from warrenXbraceModelFn -- the same source the analytical
% side uses -- and the FSD areas and beta_min are asserted before any
% sampling starts, mirroring mcNeptunSetup's guard so a long job cannot run
% on a wrong model.
%
% USAGE
%   out = resistance_model_mc();                       % 1e6 samples, both models
%   o.nTargetTotal = 1e7; out = resistance_model_mc(o);
%   o.variants = 2; resistance_model_mc(o);            % per-member only
%
% OPTIONS (all optional)
%   .nTargetTotal - total samples per variant           (default 1e6)
%   .nWorkers     - independent chunks                  (default 16)
%   .baseSeed     - chunk w gets seed baseSeed + w      (default 1000, as
%                   the published run, so chunk streams line up)
%   .subBatch     - samples per internal call           (default 5e5)
%   .poolSize     - parpool size (default min(nWorkers, cores))
%   .variants     - 1 (grouped), 2 (per-member) or [1 2] (default)
%   .outDir       - where the .mat lands (default: this directory)
%
% ESTIMATOR: raw counts are pooled (sum nFail / sum nSamples), never
% averaged betas -- beta is non-linear in Pf and a chunk with nFail == 0
% would give Inf. The CI is the normal-approximation 95 % interval on the
% pooled proportion; at low counts the Wilson interval is also reported,
% because the normal one is poor when nFail is small, which is exactly the
% case the brief warns about.
%
% See also: mcRunChunk, progressiveCollapseMCFn, resistance_model_compare,
%           tests/mc_neptun/runMcNeptun
%
% (c) S. Glanc, 2026

if nargin < 1, opts = struct(); end
def = struct('nTargetTotal', 1e6, 'nWorkers', 16, 'baseSeed', 1000, ...
             'subBatch', 5e5, 'poolSize', [], 'variants', [1 2], 'outDir', '');
fn = fieldnames(def);
for k = 1:numel(fn)
    if ~isfield(opts, fn{k}) || isempty(opts.(fn{k})), opts.(fn{k}) = def.(fn{k}); end
end

thisDir = fileparts(mfilename('fullpath'));
root    = fullfile(thisDir, '..', '..', '..', '..');
mcDir   = fullfile(thisDir, '..');
srcDir  = fullfile(root, 'system-reliability-truss-matlab', 'src');
tstDir  = fullfile(root, 'system-reliability-truss-matlab', 'tests');
exDir   = fullfile(root, 'system-reliability-truss-matlab', 'examples');
femDir  = fullfile(root, 'fem-2d-truss-matlab', 'src');
addpath(srcDir, tstDir, exDir, femDir, mcDir, thisDir);
if isempty(opts.outDir), opts.outDir = thisDir; end

nPerWorker = ceil(opts.nTargetTotal / opts.nWorkers);
nPlan      = nPerWorker * opts.nWorkers;

fprintf('===============================================================\n');
fprintf('Resistance model MC -- grouped vs per-member resistances\n');
fprintf('MATLAB %s   started %s\n', version, char(datetime('now')));
fprintf('chunks = %d x %d = %d samples per variant, seeds %d..%d\n', ...
        opts.nWorkers, nPerWorker, nPlan, opts.baseSeed + 1, opts.baseSeed + opts.nWorkers);
fprintf('===============================================================\n\n');

%% ---- model and the two rvSpec variants ---------------------------------
model     = warrenXbraceModelFn(struct('verbose', false));
nodes     = model.nodes;
members   = model.members;
kinematic = model.kinematic;
sections  = model.sections;
role      = model.role;

rv    = {model.rvSpec, model.rvSpec};
rv{2}.resGroup = (1:members.nmembers)';
rv{2}.resMean  = model.f_y * sections.A(role);
rv{2}.resStd   = rv{2}.resMean * 0.08;
vName = {'grouped (4 RV)', 'per-member (16 RV)'};

% Same guard as mcNeptunSetup: a long job must not start on a wrong model.
areasExp = [7.79481; 6.49091; 1.48074; 4.67493];
areasGot = sections.A(:) * 1e4;
fprintf('areas [cm^2] = %s\n', mat2str(areasGot', 6));
if max(abs(areasGot - areasExp) ./ areasExp) > 1e-5
    error('resistance_model_mc:areaMismatch', ...
        'FSD areas %s do not match the published %s -- do not run the MC.', ...
        mat2str(areasGot', 6), mat2str(areasExp', 6));
end
for v = 1:2
    c = componentReliabilityFn(nodes, members, kinematic, sections, rv{v});
    bmin(v) = min(c.beta); %#ok<AGROW>
    fprintf('%-20s beta_min = %.6f  Pf_min = %.8e\n', vName{v}, bmin(v), normcdf(-bmin(v)));
    if abs(bmin(v) - 3.909383) > 1e-5
        error('resistance_model_mc:betaMismatch', ...
            '%s beta_min = %.6f, expected 3.909383 -- do not run the MC.', vName{v}, bmin(v));
    end
end
fprintf('setup checks PASSED\n\n');

%% ---- pool --------------------------------------------------------------
poolSize = opts.poolSize;
if isempty(poolSize), poolSize = min(opts.nWorkers, feature('numcores')); end
p = gcp('nocreate');
if isempty(p)
    c = parcluster('local');
    if c.NumWorkers < poolSize, c.NumWorkers = poolSize; end
    p = parpool(c, poolSize);
end
fprintf('parpool: %d workers (chunks: %d)\n\n', p.NumWorkers, opts.nWorkers);
parfevalOnAll(@addpath, 0, srcDir, tstDir, mcDir, femDir);

%% ---- run each requested variant ----------------------------------------
res = struct('variant', {}, 'name', {}, 'Pf_MC', {}, 'beta_MC', {}, ...
             'nFail', {}, 'nTotal', {}, 'ciHalf', {}, 'ciWilson', {}, ...
             'nFail_all', {}, 'nSamp_all', {}, 'wallTime', {}, ...
             'failSequences', {}, 'Pf_min', {});

for v = opts.variants(:)'
    fprintf('--- %s: %d samples ---\n', vName{v}, nPlan);
    tStart = tic;
    [nF, nS, seqs] = mcAllChunksFn(nodes, members, kinematic, sections, rv{v}, ...
                                   nPerWorker, opts.baseSeed, opts.nWorkers, opts.subBatch);
    wall = toc(tStart);

    nFail  = sum(nF);
    nTotal = sum(nS);
    Pf     = nFail / nTotal;
    if Pf <= 0, beta = Inf; else, beta = -norminv(Pf); end

    r = struct();
    r.variant  = v;
    r.name     = vName{v};
    r.Pf_MC    = Pf;
    r.beta_MC  = beta;
    r.nFail    = nFail;
    r.nTotal   = nTotal;
    r.ciHalf   = 1.96 * sqrt(max(Pf, 0) * (1 - Pf) / nTotal);
    r.ciWilson = wilsonFn(nFail, nTotal, 1.96);
    r.nFail_all = nF;
    r.nSamp_all = nS;
    r.wallTime  = wall;
    r.failSequences = cat(2, seqs{:});
    r.Pf_min    = normcdf(-bmin(v));
    res(end+1) = r; %#ok<AGROW>

    covPct = 100 / max(sqrt(nFail), eps);
    fprintf('  nFail = %d / %d   Pf_MC = %.6e   beta_MC = %.4f   CoV = %.1f %%   (%.1f s)\n', ...
            nFail, nTotal, Pf, beta, covPct, wall);
    fprintf('  95%% CI (normal) [%.4e, %.4e]\n', Pf - r.ciHalf, Pf + r.ciHalf);
    fprintf('  95%% CI (Wilson) [%.4e, %.4e]\n', r.ciWilson(1), r.ciWilson(2));
    fprintf('  Pf_MC / Pf_min  = %.4f\n\n', Pf / r.Pf_min);
    if nFail < 30
        fprintf('  NOTE: only %d failure events -- treat any ratio built on this\n', nFail);
        fprintf('        as indicative only (brief section 4).\n\n');
    end
end

%% ---- summary -----------------------------------------------------------
fprintf('=== summary (%d samples per variant) ===\n', nPlan);
fprintf('%-20s %8s %14s %10s %10s\n', 'variant', 'nFail', 'Pf_MC', 'beta_MC', 'Pf/Pf_min');
for k = 1:numel(res)
    fprintf('%-20s %8d %14.6e %10.4f %10.4f\n', res(k).name, res(k).nFail, ...
            res(k).Pf_MC, res(k).beta_MC, res(k).Pf_MC / res(k).Pf_min);
end
if numel(res) == 2
    fprintf('per-member / grouped Pf_MC = %.4f\n', res(2).Pf_MC / res(1).Pf_MC);
    % Sharing chunk seeds does NOT make the two runs paired. Both draw
    % randn(n, nGroups) before randn(n, nLoads), so at nGroups 4 vs 16 the
    % load block starts from a different point in the stream and the load
    % realisations differ entirely; only the first four resistance columns
    % coincide, and even those map to different members. Treat the two
    % estimates as independent and combine their errors accordingly.
    seNaive = sqrt(res(1).Pf_MC*(1-res(1).Pf_MC)/res(1).nTotal + ...
                   res(2).Pf_MC*(1-res(2).Pf_MC)/res(2).nTotal);
    fprintf('difference Pf(per-member) - Pf(grouped) = %+.4e +- %.4e (1 s.e.)\n', ...
            res(2).Pf_MC - res(1).Pf_MC, seNaive);
    fprintf('NOTE: shared chunk seeds do NOT pair the two runs -- the extra 12\n');
    fprintf('resistance columns shift the load draws, so treat them as independent.\n');
end

out = struct('res', res, 'nPlan', nPlan, 'nWorkers', opts.nWorkers, ...
             'baseSeed', opts.baseSeed, 'subBatch', opts.subBatch, ...
             'matlabVersion', version);
outMat = fullfile(opts.outDir, sprintf('resistance_model_mc_%.0e.mat', nPlan));
save(outMat, 'out', '-v7.3');
fprintf('\nsaved -> %s\n', outMat);
end

% =========================================================================
function [nF, nS, seqs] = mcAllChunksFn(nodes, members, kinematic, sections, ...
                                        rvSpec, nPerWorker, baseSeed, nWorkers, subBatch)
% The parfor lives in its own function scope. mcRunChunk is the published
% one, used unmodified, so chunk numbers are comparable with the neptun run.
nF   = zeros(nWorkers, 1);
nS   = zeros(nWorkers, 1);
seqs = cell(nWorkers, 1);
parfor w = 1:nWorkers
    [a, b, s] = mcRunChunk(nodes, members, kinematic, sections, rvSpec, ...
                           nPerWorker, baseSeed + w, subBatch, []);
    nF(w) = a; nS(w) = b; seqs{w} = s;
end
end

% =========================================================================
function ci = wilsonFn(k, n, z)
% Wilson score interval -- honest at small counts, where the normal
% approximation on a proportion of order 1e-4 is not.
ph = k / n;
d  = 1 + z^2/n;
c  = (ph + z^2/(2*n)) / d;
h  = z * sqrt(ph*(1-ph)/n + z^2/(4*n^2)) / d;
ci = [max(c - h, 0), c + h];
end
