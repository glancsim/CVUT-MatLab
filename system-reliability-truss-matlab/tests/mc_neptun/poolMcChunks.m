function out = poolMcChunks(inDir)
% poolMcChunks  Pools mc_chunk_*.mat files written by runMcChunk into the
% same result struct runMcNeptun produces, and prints the section-7 report.
%
% Pools raw COUNTS (sum nFail / sum nSamples). Never averages beta -- beta
% is non-linear in Pf and any chunk with nFail == 0 would give Inf.
%
% (c) S. Glanc, 2026

if nargin < 1 || isempty(inDir), inDir = fileparts(mfilename('fullpath')); end
addpath(fileparts(mfilename('fullpath')));

files = dir(fullfile(inDir, 'mc_chunk_*.mat'));
if isempty(files)
    error('poolMcChunks:noChunks', 'no mc_chunk_*.mat found in %s', inDir);
end

nw = numel(files);
nFail_all = zeros(nw,1); nSamp_all = zeros(nw,1);
time_all  = zeros(nw,1); seeds     = zeros(nw,1);
wIdx = zeros(nw,1); seq_all = cell(nw,1);
mlv = '';  sb = NaN;

for k = 1:nw
    S = load(fullfile(files(k).folder, files(k).name), 'chunk');
    c = S.chunk;
    wIdx(k)      = c.w;
    seeds(k)     = c.seed;
    nFail_all(k) = c.nFail;
    nSamp_all(k) = c.nSamples;
    time_all(k)  = c.elapsed;
    seq_all{k}   = c.failSequences;
    mlv = c.matlabVersion;  sb = c.subBatch;
end

[~, ord] = sort(wIdx);
nFail_all = nFail_all(ord); nSamp_all = nSamp_all(ord);
time_all  = time_all(ord);  seeds     = seeds(ord);  seq_all = seq_all(ord);

fprintf('pooled %d chunk files from %s\n\n', nw, inDir);

nFail  = sum(nFail_all);
nTotal = sum(nSamp_all);
Pf_MC  = nFail / nTotal;
if Pf_MC <= 0, beta_MC = Inf; else, beta_MC = -norminv(Pf_MC); end
halfCI = 1.96 * sqrt(Pf_MC * (1 - Pf_MC) / nTotal);

failSequences = {};
for k = 1:nw
    failSequences = [failSequences, seq_all{k}]; %#ok<AGROW>
end

out = struct('Pf_MC', Pf_MC, 'beta_MC', beta_MC, 'nFail', nFail, ...
             'nTotal', nTotal, 'ciHalfWidth', halfCI, ...
             'nFail_all', nFail_all, 'nSamp_all', nSamp_all, ...
             'time_all', time_all, 'wallTime', max(time_all), ...
             'failSequences', {failSequences}, 'seeds', seeds, ...
             'matlabVersion', mlv, 'subBatch', sb);

mcNeptunReport(out, inDir);
save(fullfile(inDir, 'mc_neptun_result.mat'), 'out', '-v7.3');
end
