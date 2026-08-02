here = fileparts(mfilename('fullpath'));
addpath(here); addpath(fullfile(here, '..'));
[nodes, members, kinematic, sections, rvSpec] = mcNeptunSetup();
seeds = [42 1]; A = cell(1,2);
for k = 1:2
    rng(seeds(k));
    A{k} = systemReliabilityFn(nodes, members, kinematic, sections, rvSpec, ...
                               struct('eta',0,'rho0',0.7,'verbose',false));
end
R1 = A{1}; R2 = A{2};

%% do the representative SEQUENCES differ between seeds?
q = numel(R1.cutSets);
diffSeq = false(q,1);
for i = 1:q
    diffSeq(i) = ~isequal(R1.repSequence{i}, R2.repSequence{i});
end
fprintf('\n=== repSequence differs for %d of %d cut-sets (%.1f %%) ===\n', ...
        sum(diffSeq), q, 100*sum(diffSeq)/q);

fprintf('\n%-16s %-22s %-22s %10s %10s\n','cut-set','seq seed42','seq seed1','bT 42','bT 1');
idx = find(diffSeq);
[~,o] = sort(min(R1.betaTilde(idx), R2.betaTilde(idx)));
for r = 1:min(12,numel(idx))
    i = idx(o(r));
    fprintf('%-16s %-22s %-22s %10.4f %10.4f\n', ...
        mat2str(sort(R1.cutSets{i}(:))'), mat2str(R1.repSequence{i}), ...
        mat2str(R2.repSequence{i}), R1.betaTilde(i), R2.betaTilde(i));
end

%% the phantom group {4,8,9,16}
key = @(v) mat2str(sort(v(:))');
allK = cellfun(key, R1.cutSets, 'UniformOutput', false);
j = find(strcmp(allK,'[4 8 9 16]'),1);
fprintf('\n=== the phantom group {4,8,9,16} ===\n');
fprintf('seed 42: seq %-22s betaTilde %.6f  Pf %.4e\n', ...
    mat2str(R1.repSequence{j}), R1.betaTilde(j), normcdf(-R1.betaTilde(j)));
fprintf('seed  1: seq %-22s betaTilde %.6f  Pf %.4e\n', ...
    mat2str(R2.repSequence{j}), R2.betaTilde(j), normcdf(-R2.betaTilde(j)));
fprintf('MC observed this cut-set: 0 times in 1e7 samples\n');

%% is betaTilde reproducible at all for the dominant cut-sets?
fprintf('\n=== betaTilde reproducibility, 10 lowest-beta cut-sets ===\n');
[~,lo] = sort(R1.betaTilde,'ascend');
fprintf('%-16s %10s %10s %10s\n','cut-set','bT 42','bT 1','diff');
for r = 1:10
    i = lo(r);
    fprintf('%-16s %10.6f %10.6f %10.2e\n', mat2str(sort(R1.cutSets{i}(:))'), ...
        R1.betaTilde(i), R2.betaTilde(i), abs(R1.betaTilde(i)-R2.betaTilde(i)));
end
