function out = runMcNeptun(opts)
% runMcNeptun  Monte Carlo cross-check of beta_sys for the Warren X-brace
% truss (MC_NEPTUN_BRIEF.md), parallelised as 28 independent seeded chunks.
%
% USAGE (neptun01, 32 cores, use 28 -- shared machine):
%   matlab -batch "run('~/MatLab/system-reliability-truss-matlab/tests/mc_neptun/run_mc.m')"
%
% Direct call:
%   out = runMcNeptun();                     % 1e8 samples, 28 chunks
%   o.nTargetTotal = 1e7; runMcNeptun(o);    % brief's original target
%
% OPTIONS (all optional):
%   .nTargetTotal - total samples across all chunks     (default 1e8)
%   .nWorkers     - number of independent chunks        (default 28)
%   .baseSeed     - chunk w gets seed baseSeed + w      (default 1000)
%   .subBatch     - samples per internal call, caps peak memory per worker
%                   (default 5e5; 0 or Inf disables). The seed is set ONCE
%                   per chunk and the RNG stream then CONTINUES across
%                   sub-batches, so this is still "one seed per chunk" as
%                   the brief requires, and remains reproducible. It is not
%                   bit-identical to one monolithic call, because the
%                   randn(n,4)/randn(n,2) draws interleave differently.
%   .poolSize     - workers in the parpool (default min(nWorkers, cores))
%   .outDir       - where results land (default: this directory)
%
% The chunk count is deliberately DECOUPLED from the pool size: pooling raw
% counts (sum nFail / sum nSamples) is exact regardless of concurrency, so
% 28 chunks give the same answer on 28 cores as on 16.
%
% Deliberately NOT done (brief section 3): progressiveCollapseMCFn is left
% serial inside. Do not rewrite it into a parfor.
%
% Contains no nested functions, so the parfor below is safe on older
% releases (neptun01 runs R2023a).
%
% (c) S. Glanc, 2026

if nargin < 1, opts = struct(); end
def = struct('nTargetTotal', 1e8, 'nWorkers', 28, 'baseSeed', 1000, ...
             'subBatch', 5e5, 'poolSize', [], 'outDir', '');
fn = fieldnames(def);
for k = 1:numel(fn)
    if ~isfield(opts, fn{k}) || isempty(opts.(fn{k})), opts.(fn{k}) = def.(fn{k}); end
end

thisDir = fileparts(mfilename('fullpath'));
if isempty(opts.outDir), opts.outDir = thisDir; end
addpath(thisDir);

nWorkers   = opts.nWorkers;
nPerWorker = ceil(opts.nTargetTotal / nWorkers);
nTotalPlan = nPerWorker * nWorkers;

fprintf('===============================================================\n');
fprintf('MC cross-check of beta_sys -- Warren X-brace truss\n');
fprintf('MATLAB %s   started %s\n', version, char(datetime('now')));
fprintf('chunks = %d, samples/chunk = %d, planned total = %d\n', ...
        nWorkers, nPerWorker, nTotalPlan);
fprintf('seeds  = %d .. %d\n', opts.baseSeed + 1, opts.baseSeed + nWorkers);
fprintf('===============================================================\n\n');

%% ---- setup (asserts the brief's deterministic checks) ------------------
[nodes, members, kinematic, sections, rvSpec] = mcNeptunSetup();
fprintf('\n');

%% ---- pool --------------------------------------------------------------
poolSize = opts.poolSize;
if isempty(poolSize), poolSize = min(nWorkers, feature('numcores')); end

p = gcp('nocreate');
if isempty(p)
    c = parcluster('local');
    if c.NumWorkers < poolSize, c.NumWorkers = poolSize; end
    p = parpool(c, poolSize);
end
fprintf('parpool: %d workers (chunks: %d)\n', p.NumWorkers, nWorkers);

srcPaths = { fullfile(thisDir, '..', '..', 'src'), ...
             fullfile(thisDir, '..'), ...
             fullfile(thisDir, '..', '..', '..', 'fem-2d-truss-matlab', 'src'), ...
             thisDir };
parfevalOnAll(@addpath, 0, srcPaths{:});

%% ---- run ---------------------------------------------------------------
tStart = tic;
mcProgressTick(-1, nTotalPlan, tStart);       % reset the progress counter

q = parallel.pool.DataQueue;
afterEach(q, @(n) mcProgressTick(n, nTotalPlan, tStart));

[nFail_all, nSamp_all, time_all, seq_all] = ...
    mcRunAllChunks(nodes, members, kinematic, sections, rvSpec, ...
                   nPerWorker, opts.baseSeed, nWorkers, opts.subBatch, q);
wallTime = toc(tStart);

%% ---- pool the COUNTS (never average beta) ------------------------------
nFail  = sum(nFail_all);
nTotal = sum(nSamp_all);
Pf_MC  = nFail / nTotal;
if Pf_MC <= 0
    beta_MC = Inf;
else
    beta_MC = -norminv(Pf_MC);
end
halfCI = 1.96 * sqrt(Pf_MC * (1 - Pf_MC) / nTotal);

failSequences = {};
for w = 1:nWorkers
    failSequences = [failSequences, seq_all{w}]; %#ok<AGROW>
end

out = struct('Pf_MC', Pf_MC, 'beta_MC', beta_MC, 'nFail', nFail, ...
             'nTotal', nTotal, 'ciHalfWidth', halfCI, ...
             'nFail_all', nFail_all, 'nSamp_all', nSamp_all, ...
             'time_all', time_all, 'wallTime', wallTime, ...
             'failSequences', {failSequences}, ...
             'seeds', (opts.baseSeed + (1:nWorkers))', ...
             'matlabVersion', version, 'subBatch', opts.subBatch);

mcNeptunReport(out, opts.outDir);
save(fullfile(opts.outDir, 'mc_neptun_result.mat'), 'out', '-v7.3');
end

% =========================================================================
function [nFail_all, nSamp_all, time_all, seq_all] = ...
        mcRunAllChunks(nodes, members, kinematic, sections, rvSpec, ...
                       nPerWorker, baseSeed, nWorkers, subBatch, q)
% The parfor lives in its own function scope, isolated from anything else.

nFail_all = zeros(nWorkers, 1);
nSamp_all = zeros(nWorkers, 1);
time_all  = zeros(nWorkers, 1);
seq_all   = cell(nWorkers, 1);

parfor w = 1:nWorkers
    tw = tic;
    [nF, nS, seqs] = mcRunChunk(nodes, members, kinematic, sections, rvSpec, ...
                                nPerWorker, baseSeed + w, subBatch, q);
    nFail_all(w) = nF;
    nSamp_all(w) = nS;
    seq_all{w}   = seqs;
    time_all(w)  = toc(tw);
end
end

% =========================================================================
function mcProgressTick(n, nTotalPlan, tStart)
% Client-side progress accumulator for the DataQueue. State lives in a
% persistent variable rather than a nested-function closure. Call with
% n < 0 to reset before a run.

persistent done
if isempty(done) || n < 0
    done = 0;
    if n < 0, return; end
end

done = done + n;
el   = toc(tStart);
frac = done / nTotalPlan;
fprintf('  progress %6.2f %%  |  %.3e / %.3e samples  |  %.0f s elapsed  |  ETA %.0f s\n', ...
        100*frac, done, nTotalPlan, el, el * (1/max(frac, eps) - 1));
end
