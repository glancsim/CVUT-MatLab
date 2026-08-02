% mode_stats.m
%
% Produces sections 3 and 6 of MC_NEPTUN_FINDINGS.md from the raw MC output:
%
%   (a) every distinct mechanism observed, with counts and Pf
%   (b) the mechanism-size distribution (2- vs 3- vs 4-member)
%   (c) the count for {4,8,9,16} -- the "phantom" PNET group of section 4;
%       zero occurrences is what makes the rng(42) branch an artefact
%   (d) a completeness check of nullSpaceCutSetsFn: does every observed
%       mechanism contain a minimal cut-set from the analytical enumeration?
%
% A mechanism label here is the SORTED SET of all members removed in that
% sample, which is not necessarily minimal -- an extra member can fail on
% the way to the mechanism. Check (d) resolves those against the minimal
% cut-sets rather than reporting them as missing.
%
% (c) S. Glanc, 2026

here = fileparts(mfilename('fullpath'));
addpath(here); addpath(fullfile(here, '..'));

matFile = fullfile(here, '..', 'mc_neptun_result.mat');
if ~isfile(matFile)
    error('mode_stats:noResult', ...
        ['%s not found -- run runMcNeptun first (the .mat is git-ignored, ' ...
         'see ../README.md).'], matFile);
end
S = load(matFile); o = S.out;
fprintf('nFail = %d / %d   Pf_MC = %.8e   beta_MC = %.6f\n', ...
        o.nFail, o.nTotal, o.Pf_MC, o.beta_MC);

k = cellfun(@(s) mat2str(sort(s(:))'), o.failSequences, 'UniformOutput', false);
[u, ~, ic] = unique(k);
cnt = accumarray(ic(:), 1);
[cnt, ord] = sort(cnt, 'descend');
u = u(ord);

%% (a) all distinct mechanisms
fprintf('\n=== all %d distinct mechanisms observed ===\n', numel(u));
fprintf('%-22s %8s %10s %14s\n', 'members', 'count', 'share', 'Pf');
for i = 1:numel(u)
    fprintf('%-22s %8d %9.3f %% %14.4e\n', u{i}, cnt(i), ...
            100*cnt(i)/o.nFail, cnt(i)/o.nTotal);
end

%% (b) size distribution
sz = cellfun(@numel, o.failSequences);
fprintf('\n=== mechanism sizes ===\n');
for s = unique(sz)
    fprintf('  %d members: %6d (%6.3f %%)   Pf = %.4e\n', ...
            s, sum(sz == s), 100*mean(sz == s), sum(sz == s)/o.nTotal);
end

%% (c) the phantom group
fprintf('\n*** {4,8,9,16} observed: %d times ***\n', sum(strcmp(k, '[4 8 9 16]')));

%% (d) completeness of the cut-set enumeration
[nodes, members, kinematic, sections, rvSpec] = mcNeptunSetup();
rng(42);
R = systemReliabilityFn(nodes, members, kinematic, sections, rvSpec, ...
                        struct('eta', 0, 'rho0', 0.7, 'verbose', false));
cutKeys = cellfun(@(v) mat2str(sort(v(:))'), R.cutSets, 'UniformOutput', false);

fprintf('\n=== completeness vs the %d analytical minimal cut-sets ===\n', numel(R.cutSets));
fprintf('%-22s %-10s %s\n', 'observed', 'is minimal', 'minimal cut-set(s) contained');
orphans = {};
for i = 1:numel(u)
    v = str2num(u{i}); %#ok<ST2NM>
    isMinimal = any(strcmp(cutKeys, u{i}));
    contained = {};
    for q = 1:numel(R.cutSets)
        cs = sort(R.cutSets{q}(:))';
        if all(ismember(cs, v)), contained{end+1} = mat2str(cs); end %#ok<AGROW>
    end
    if isempty(contained), orphans{end+1} = u{i}; end %#ok<AGROW>
    fprintf('%-22s %-10s %s\n', u{i}, string(isMinimal), strjoin(contained, ' '));
end

if isempty(orphans)
    fprintf('\nPASS: every observed mechanism contains a minimal cut-set.\n');
else
    fprintf('\n*** FAIL: %d observed mechanism(s) contain NO minimal cut-set: %s\n', ...
            numel(orphans), strjoin(orphans', ' '));
    fprintf('*** nullSpaceCutSetsFn would be incomplete -- investigate.\n');
end
