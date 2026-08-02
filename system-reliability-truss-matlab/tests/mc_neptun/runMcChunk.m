function runMcChunk(w, nPerWorker, baseSeed, subBatch, outDir)
% runMcChunk  Single-chunk entry point for the NO-Parallel-Computing-Toolbox
% fallback described in MC_NEPTUN_BRIEF.md section 3.
%
% Launch 28 separate processes, then pool with poolMcChunks:
%
%   for w in $(seq 1 28); do
%       matlab -batch "runMcChunk($w)" > chunk_$w.log 2>&1 &
%   done
%   wait
%   matlab -batch "poolMcChunks"
%
% Defaults match runMcNeptun exactly (1e8 total over 28 chunks), so the two
% paths give identical numbers for the same chunk index.
%
% (c) S. Glanc, 2026

if nargin < 2 || isempty(nPerWorker), nPerWorker = ceil(1e8 / 28); end
if nargin < 3 || isempty(baseSeed),   baseSeed   = 1000;           end
if nargin < 4 || isempty(subBatch),   subBatch   = 5e5;            end
if nargin < 5 || isempty(outDir),     outDir     = fileparts(mfilename('fullpath')); end

addpath(fileparts(mfilename('fullpath')));
[nodes, members, kinematic, sections, rvSpec] = mcNeptunSetup();

seed = baseSeed + w;
fprintf('\nchunk %d: %d samples, seed %d\n', w, nPerWorker, seed);

t = tic;
[nFail, nSamples, seqs] = mcRunChunk(nodes, members, kinematic, sections, ...
                                     rvSpec, nPerWorker, seed, subBatch, []);
elapsed = toc(t);

chunk = struct('w', w, 'seed', seed, 'nFail', nFail, 'nSamples', nSamples, ...
               'elapsed', elapsed, 'failSequences', {seqs}, ...
               'matlabVersion', version, 'subBatch', subBatch);

f = fullfile(outDir, sprintf('mc_chunk_%02d.mat', w));
save(f, 'chunk', '-v7.3');

fprintf('chunk %d DONE: nFail = %d / %d, %.1f s (%.0f samples/s) -> %s\n', ...
        w, nFail, nSamples, elapsed, nSamples/elapsed, f);
end
