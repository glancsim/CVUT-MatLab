function [nFail, nSamples, seqs] = mcRunChunk(nodes, members, kinematic, ...
                                              sections, rvSpec, nPerWorker, ...
                                              seed, subBatch, q)
% mcRunChunk  One independent MC chunk of the progressive-collapse oracle.
%
% Shared by runMcNeptun (parfor path) and runMcChunk (matlab -batch path)
% so both produce identical numbers for the same (seed, nPerWorker,
% subBatch).
%
% The RNG seed is applied on the FIRST internal call only; later sub-batches
% omit opts.seed, so progressiveCollapseMCFn does not call rng() and the
% chunk's stream continues uninterrupted. That keeps the brief's "one seed
% per chunk" contract while bounding peak memory: progressiveCollapseMCFn
% pre-allocates randn(nSamples, nGroups) up front, so a monolithic 3.57e6
% call costs ~340 MB per worker (~10 GB across 28), whereas subBatch = 5e5
% costs ~48 MB per worker.
%
%   q - (optional) parallel.pool.DataQueue for progress; [] to disable
%
% (c) S. Glanc, 2026

if nargin < 9, q = []; end

if isempty(subBatch) || subBatch <= 0 || ~isfinite(subBatch)
    subBatch = nPerWorker;
end

nFail = 0; nSamples = 0; seqs = {};
remaining = nPerWorker;
first = true;

while remaining > 0
    n = min(subBatch, remaining);

    o = struct('verbose', false);
    if first
        o.seed = seed;   % set ONCE per chunk; stream continues afterwards
        first = false;
    end

    [~, r] = progressiveCollapseMCFn(nodes, members, kinematic, sections, ...
                                     rvSpec, n, o);

    nFail    = nFail + r.nFail;
    nSamples = nSamples + r.nSamples;
    if ~isempty(r.failSequences)
        seqs = [seqs, r.failSequences]; %#ok<AGROW>
    end

    remaining = remaining - n;
    if ~isempty(q), send(q, n); end
end
end
