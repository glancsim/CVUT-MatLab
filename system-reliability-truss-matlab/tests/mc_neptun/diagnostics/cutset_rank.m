here = fileparts(mfilename('fullpath'));
addpath(here); addpath(fullfile(here, '..'));
[nodes, members, kinematic, sections, rvSpec] = mcNeptunSetup();

opts = struct('eta', 0, 'rho0', 0.7, 'verbose', false);
t = tic;
R = systemReliabilityFn(nodes, members, kinematic, sections, rvSpec, opts);
fprintf('\nsystemReliabilityFn: %.1f s\n', toc(t));
fprintf('beta_sys = %.6f  Pf_sys = %.8e  (expect 1.11915173e-04)\n', R.beta_sys, R.Pf_sys);
fprintf('gH = %d, nCutSets = %d\n\n', R.gH, numel(R.cutSets));

%% key(): canonical string for a member set
key = @(v) mat2str(sort(v(:))');
allKeys = cellfun(key, R.cutSets, 'UniformOutput', false);

%% --- CHECK 1: are the MC-observed mechanisms in the analytical list? -----
mcObserved = {[11 14], [2 5], [10 16], [13 16], [7 11]};
fprintf('=== CHECK 1: MC-observed mechanisms present among the %d cut-sets? ===\n', numel(R.cutSets));
for i = 1:numel(mcObserved)
    k = key(mcObserved{i});
    idx = find(strcmp(allKeys, k), 1);
    if isempty(idx)
        fprintf('  %-10s : *** NOT IN CUT-SET LIST -- nullSpaceCutSetsFn missed it ***\n', k);
    else
        fprintf('  %-10s : present, cut-set #%d, betaPerCutSet = %.4f\n', k, idx, R.betaPerCutSet(idx));
    end
end
fprintf('\n');

%% --- CHECK 2: full ranking by betaPerCutSet ------------------------------
[bs, ord] = sort(R.betaPerCutSet, 'ascend');
fprintf('=== CHECK 2: all cut-sets ranked by betaPerCutSet (top 20) ===\n');
fprintf('%5s  %-16s %-24s %10s %14s\n', 'rank', 'cut-set', 'rep. sequence', 'beta_p', 'Pf_p');
for r = 1:min(20, numel(ord))
    i = ord(r);
    fprintf('%5d  %-16s %-24s %10.4f %14.4e\n', r, mat2str(sort(R.cutSets{i}(:))'), ...
        mat2str(R.repSequence{i}), R.betaPerCutSet(i), normcdf(-R.betaPerCutSet(i)));
end
fprintf('\n');

%% --- CHECK 3: where do the brief's dominant three rank? ------------------
briefTop = {[11 14], [1 2 8], [5 12]};
fprintf('=== CHECK 3: rank of the brief''s three dominant cut-sets ===\n');
for i = 1:numel(briefTop)
    k = key(briefTop{i});
    idx = find(strcmp(allKeys, k), 1);
    if isempty(idx)
        fprintf('  %-10s : NOT IN CUT-SET LIST\n', k);
    else
        r = find(ord == idx, 1);
        fprintf('  %-10s : cut-set #%d, rank %d/%d, beta_p = %.4f, Pf_p = %.4e, size %d\n', ...
            k, idx, r, numel(ord), R.betaPerCutSet(idx), ...
            normcdf(-R.betaPerCutSet(idx)), numel(R.cutSets{idx}));
    end
end
fprintf('\n');

%% --- CHECK 4: rank of MC-observed sets + cut-set size distribution -------
fprintf('=== CHECK 4: rank of MC-observed sets ===\n');
for i = 1:numel(mcObserved)
    k = key(mcObserved{i});
    idx = find(strcmp(allKeys, k), 1);
    if ~isempty(idx)
        r = find(ord == idx, 1);
        fprintf('  %-10s : rank %d/%d, beta_p = %.4f, Pf_p = %.4e\n', ...
            k, r, numel(ord), R.betaPerCutSet(idx), normcdf(-R.betaPerCutSet(idx)));
    end
end
sz = cellfun(@numel, R.cutSets);
fprintf('\ncut-set sizes: ');
for s = unique(sz(:))'
    fprintf('%d members: %d   ', s, sum(sz == s));
end
fprintf('\n');

%% --- CHECK 5: PNET grouping -- what actually drives Pf_sys ---------------
fprintf('\n=== CHECK 5: PNET groups (rho0 = 0.7) ===\n');
[~, po] = sort([R.pnetGroups.beta], 'ascend');
fprintf('%5s  %-16s %10s %14s %8s\n', 'rank', 'representative', 'beta', 'Pf', 'absorbed');
PfSum = 0;
for r = 1:numel(po)
    g = R.pnetGroups(po(r));
    Pfg = normcdf(-g.beta);
    PfSum = PfSum + Pfg;
    fprintf('%5d  %-16s %10.4f %14.4e %8d\n', r, ...
        mat2str(sort(R.cutSets{g.repIdx}(:))'), g.beta, Pfg, numel(g.members));
end
fprintf('\nnPnetGroups = %d (of %d cut-sets), sum Pf_i = %.8e\n', ...
    numel(R.pnetGroups), numel(R.cutSets), PfSum);

save('cutset_rank.mat', 'R');
