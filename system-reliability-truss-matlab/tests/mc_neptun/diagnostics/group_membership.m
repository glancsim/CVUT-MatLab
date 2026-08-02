% group_membership.m
%
% Produces the "PNET group vs MC" table of MC_NEPTUN_FINDINGS.md section 2:
% maps every mechanism the Monte Carlo actually observed onto the PNET
% correlation group it belongs to, and contrasts the probability PNET
% assigns to that group against the probability the MC measures for it.
%
% Reads the MC counts from ../mc_neptun_result.mat (produced by
% runMcNeptun / poolMcChunks) -- nothing is hard-coded, so re-running after
% a new MC run updates the table automatically.
%
% Uses rng(42), i.e. the branch quoted in MC_NEPTUN_BRIEF.md. See
% MC_NEPTUN_FINDINGS.md section 4 for why the branch matters.
%
% (c) S. Glanc, 2026

here = fileparts(mfilename('fullpath'));
addpath(here); addpath(fullfile(here, '..'));

matFile = fullfile(here, '..', 'mc_neptun_result.mat');
if ~isfile(matFile)
    error('group_membership:noResult', ...
        ['%s not found -- run runMcNeptun first (the .mat is git-ignored, ' ...
         'see ../README.md).'], matFile);
end
S = load(matFile); o = S.out;
fprintf('MC: nFail = %d / %d, Pf_MC = %.8e\n', o.nFail, o.nTotal, o.Pf_MC);

% observed mechanisms, keyed by the sorted set of removed members
k = cellfun(@(s) mat2str(sort(s(:))'), o.failSequences, 'UniformOutput', false);
[u, ~, ic] = unique(k);
cnt = accumarray(ic(:), 1);

%% analytical side
[nodes, members, kinematic, sections, rvSpec] = mcNeptunSetup();
rng(42);
R = systemReliabilityFn(nodes, members, kinematic, sections, rvSpec, ...
                        struct('eta', 0, 'rho0', 0.7, 'verbose', false));
fprintf('Pf_sys (rng 42) = %.8e\n', R.Pf_sys);

allK = cellfun(@(v) mat2str(sort(v(:))'), R.cutSets, 'UniformOutput', false);
[~, po] = sort([R.pnetGroups.beta], 'ascend');
grpOf = zeros(numel(R.cutSets), 1);
for r = 1:numel(po)
    grpOf(R.pnetGroups(po(r)).members) = r;
end

%% table
nShow = min(6, numel(po));
fprintf('\n=== PNET group vs MC ===\n');
fprintf('%6s %-16s %14s %14s %10s\n', 'grp', 'representative', 'PNET Pf', 'MC Pf', 'ratio');
accounted = 0;
for r = 1:nShow
    rep = R.pnetGroups(po(r)).repIdx;
    PfP = normcdf(-R.pnetGroups(po(r)).beta);
    mcSum = 0;
    for i = 1:numel(u)
        j = find(strcmp(allK, u{i}), 1);
        if ~isempty(j) && grpOf(j) == r
            mcSum = mcSum + cnt(i) / o.nTotal;
        end
    end
    accounted = accounted + mcSum;
    if PfP > 0, ratio = sprintf('%.2f', mcSum / PfP); else, ratio = '-'; end
    fprintf('%6d %-16s %14.4e %14.4e %10s\n', r, allK{rep}, PfP, mcSum, ratio);
end
fprintf('\nMC Pf accounted in groups 1-%d: %.6e of %.6e\n', nShow, accounted, o.Pf_MC);
