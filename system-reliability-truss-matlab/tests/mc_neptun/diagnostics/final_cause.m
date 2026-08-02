here = fileparts(mfilename('fullpath'));
addpath(here); addpath(fullfile(here, '..'));
[nodes, members, kinematic, sections, rvSpec] = mcNeptunSetup();
seeds = [42 1]; A = cell(1,2);
for k = 1:2
    rng(seeds(k));
    A{k} = systemReliabilityFn(nodes, members, kinematic, sections, rvSpec, ...
                               struct('eta',0,'rho0',0.7,'verbose',false));
end
R1=A{1}; R2=A{2};
key = @(v) mat2str(sort(v(:))');
allK = cellfun(key, R1.cutSets, 'UniformOutput', false);
gi = @(s) find(strcmp(allK,s),1);

reps  = {'[11 14]','[1 2 8]','[5 12]'};
targ  = gi('[4 8 9 16]');

fprintf('\n=== rho( {4,8,9,16} , each earlier representative ) ===\n');
fprintf('%-10s %14s %14s %10s %10s\n','rep','rho seed42','rho seed1','>=0.7 (42)','>=0.7 (1)');
for r = 1:numel(reps)
    i = gi(reps{r});
    c1 = R1.alphaTilde(i,:) * R1.alphaTilde(targ,:)';
    c2 = R2.alphaTilde(i,:) * R2.alphaTilde(targ,:)';
    fprintf('%-10s %14.6f %14.6f %10d %10d\n', reps{r}, c1, c2, c1>=0.7, c2>=0.7);
end

fprintf('\n=== alphaTilde noise for the DOMINANT cut-sets only (identical betaTilde) ===\n');
[~,lo] = sort(R1.betaTilde,'ascend');
dom = lo(1:12);
d = max(abs(R1.alphaTilde(dom,:) - R2.alphaTilde(dom,:)), [], 2);
fprintf('%-16s %12s %14s\n','cut-set','|d betaTilde|','max |d alpha|');
for r = 1:numel(dom)
    i = dom(r);
    fprintf('%-16s %12.2e %14.3e\n', mat2str(sort(R1.cutSets{i}(:))'), ...
        abs(R1.betaTilde(i)-R2.betaTilde(i)), d(r));
end
fprintf('\n-> betaTilde reproduces exactly, alphaTilde (finite-difference gradient) does NOT\n');
fprintf('   median |d alpha| over dominant cut-sets: %.3e\n', median(d));
