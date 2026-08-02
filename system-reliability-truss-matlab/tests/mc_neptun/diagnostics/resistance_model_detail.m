% resistance_model_detail.m
%
% Post-hoc detail extraction from resistance_model_compare.mat, for the
% narrative half of `ctu-nnm-2026/RESISTANCE_MODEL_REPORT.md`. Recomputes
% nothing -- it only digs into what the comparison run already saved, so it
% costs a second and cannot disagree with the table.
%
% Answers the questions the summary table raises but does not settle:
%   * exactly how tight is the lower bound in each model, and through WHICH
%     cut-set -- the grouped model's bound runs through {11,14}, and the
%     per-member model's through something else;
%   * which failure SEQUENCE realises each of those cut-sets, since a bound
%     that stays tight has to be tight for a reason, and the reason is
%     visible in the ordering;
%   * how many cut-sets sit on the beta_min tie that the paper attributes to
%     the shared diagonal resistance;
%   * where the extra PNET groups come from when the correlations collapse.
%
% Run resistance_model_compare.m first.
%
% (c) S. Glanc, 2026

thisDir = fileparts(mfilename('fullpath'));
S = load(fullfile(thisDir, 'resistance_model_compare.mat'));
cmp = S.cmp; res = S.res;
name = cmp.name;

fprintf('=== detail: %s vs %s ===\n\n', name{1}, name{2});

%% 1. The lower bound: which cut-set carries it, and how tightly ----------
fprintf('--- 1. Lower bound, full precision ---\n');
for v = 1:2
    b = res{v}.betaPerCutSet;
    [bw, iw] = min(b);
    tie = find(abs(b - bw) < 1e-9);
    fprintf('%-20s beta_min          = %.10f\n', name{v}, cmp.beta_min(v));
    fprintf('%-20s min_p beta_p      = %.10f  via %s\n', '', bw, mat2str(res{v}.cutSets{iw}));
    fprintf('%-20s min beta_p - beta_min = %+.3e\n', '', bw - cmp.beta_min(v));
    fprintf('%-20s cut-sets tied at that beta_p (1e-9): %d  ->  %s\n', '', numel(tie), ...
        strjoin(cellfun(@mat2str, res{v}.cutSets(tie)', 'UniformOutput', false), ' '));
    fprintf('%-20s sequence of the worst cut-set: %s\n', '', mat2str(res{v}.repSequence{iw}));
    % the {11,14} cut-set specifically
    ci = find(cellfun(@(c) isequal(sort(c(:))', [11 14]), res{v}.cutSets), 1);
    fprintf('%-20s beta_p({11,14})   = %.10f  (%+.3e vs beta_min), sequence %s\n\n', '', ...
        res{v}.betaPerCutSet(ci), res{v}.betaPerCutSet(ci) - cmp.beta_min(v), ...
        mat2str(res{v}.repSequence{ci}));
end

%% 2. Distribution of beta_p over all 91 cut-sets -------------------------
fprintf('--- 2. beta_p over all %d cut-sets ---\n', numel(res{1}.cutSets));
fprintf('%-20s %10s %10s %10s %10s %10s\n', 'variant', 'min', 'p10', 'median', 'max', 'n<4.5');
for v = 1:2
    b = res{v}.betaPerCutSet;
    fprintf('%-20s %10.4f %10.4f %10.4f %10.4f %10d\n', name{v}, min(b), ...
        prctile(b, 10), median(b), max(b), sum(b < 4.5));
end
% How many cut-sets are within 0.2 of the worst -- the "many comparable
% paths" claim the paper's mechanism rests on.
fprintf('cut-sets within 0.2 of min beta_p:');
for v = 1:2
    fprintf('  %s: %d', name{v}, sum(res{v}.betaPerCutSet <= min(res{v}.betaPerCutSet) + 0.2));
end
fprintf('\n\n');

%% 3. Where the extra PNET groups come from -------------------------------
fprintf('--- 3. PNET grouping ---\n');
for v = 1:2
    g = res{v}.pnetGroups;
    sizes = arrayfun(@(x) numel(x.members), g);
    [~, ord] = sort([g.beta], 'ascend');
    Pf_g = normcdf(-[g.beta]);
    fprintf('%-20s %d groups, largest absorbs %d cut-sets, %d singletons\n', ...
        name{v}, numel(g), max(sizes), sum(sizes == 1));
    fprintf('%-20s sum of group Pf = %.6e, Pf_sys = %.6e (union corr. %.2e)\n', '', ...
        sum(Pf_g), res{v}.Pf_sys, sum(Pf_g) - res{v}.Pf_sys);
    fprintf('%-20s worst group share of summed Pf = %.4f\n', '', max(Pf_g)/sum(Pf_g));
    fprintf('%-20s five worst groups:\n', '');
    for r = 1:min(5, numel(ord))
        k = ord(r);
        fprintf('%-20s   %-14s beta %.4f  Pf %.4e  absorbs %2d  share %.4f\n', '', ...
            mat2str(res{v}.cutSets{g(k).repIdx}), g(k).beta, Pf_g(k), ...
            numel(g(k).members), Pf_g(k)/sum(Pf_g));
    end
    fprintf('\n');
end

%% 4. The four leading MC mechanisms: are they still merged? --------------
% The paper's diagnosis is that PNET folds {11,14}, {13,16}, {7,11} and
% {10,16} -- four mechanisms the simulation sees as mutually exclusive --
% into one group. Check whether they are still merged per-member.
LEAD = {[11 14], [13 16], [7 11], [10 16]};
fprintf('--- 4. Are the four leading MC mechanisms still merged? ---\n');
for v = 1:2
    idx = cellfun(@(t) find(cellfun(@(c) isequal(sort(c(:))', t), res{v}.cutSets), 1), LEAD);
    gid = zeros(1, numel(idx));
    for k = 1:numel(idx)
        for gg = 1:numel(res{v}.pnetGroups)
            if any(res{v}.pnetGroups(gg).members == idx(k)), gid(k) = gg; break; end
        end
    end
    fprintf('%-20s group id per mechanism: %s  ->  %d distinct group(s)\n', ...
        name{v}, mat2str(gid), numel(unique(gid)));
    % pairwise correlation among just these four
    R = res{v}.alphaTilde(idx, :) * res{v}.alphaTilde(idx, :)';
    R = (R + R')/2; R(1:5:end) = 1;
    m = triu(true(4), 1);
    fprintf('%-20s their 6 pairwise rho: min %.3f  max %.3f  mean %.3f  (n>=0.7: %d)\n\n', ...
        '', min(R(m)), max(R(m)), mean(R(m)), sum(R(m) >= 0.7));
end

%% 5. Seed scatter ---------------------------------------------------------
fprintf('--- 5. QMC seed scatter ---\n');
for v = 1:2
    b = cmp.betaSeeds(:, v);
    u = uniquetol(b, 1e-6, 'DataScale', 1);
    fprintf('%-20s mean %.6f  std %.6f  range [%.6f %.6f]  %d distinct value(s)\n', ...
        name{v}, mean(b), std(b), min(b), max(b), numel(u));
    if numel(u) <= 4
        for k = 1:numel(u)
            fprintf('%-20s   %.6f  x%d\n', '', u(k), sum(abs(b - u(k)) < 1e-6));
        end
    end
    fprintf('%-20s groups %d..%d, seed-42 value %.6f\n', '', ...
        min(cmp.groupSeeds(:,v)), max(cmp.groupSeeds(:,v)), cmp.beta_sys(v));
end
