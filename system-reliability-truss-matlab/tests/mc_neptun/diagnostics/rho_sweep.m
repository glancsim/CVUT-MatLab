here = fileparts(mfilename('fullpath'));
addpath(here); addpath(fullfile(here, '..'));
[nodes, members, kinematic, sections, rvSpec] = mcNeptunSetup();

PF_MC = 1.82299927e-04; CI = [1.73932159e-04 1.90667695e-04];
rhos = [0.5 0.6 0.7 0.8 0.9 0.95 0.98 0.99 0.995 0.999 0.9999];

for seed = [42 1]
    rng(seed);
    R = systemReliabilityFn(nodes, members, kinematic, sections, rvSpec, ...
                            struct('eta',0,'rho0',0.7,'verbose',false));
    fprintf('\n########## seed %d (Pf_sys@0.7 = %.6e) ##########\n', seed, R.Pf_sys);
    fprintf('%8s %14s %14s %8s %10s | %14s %8s\n', ...
        'rho0','Pf orig','Pf tiebreak','nGrp','Pf/Pf_MC','ratio(tb)','nGrp');
    for rho = rhos
        [~, Pf1, g1] = pnetSystemReliabilityFn(R.betaTilde, R.alphaTilde, rho);
        [~, Pf2, g2] = pnetTieBreakFn(R.betaTilde, R.alphaTilde, rho);
        fprintf('%8.4f %14.6e %14.6e %8d %10.3f | %14.3f %8d\n', ...
            rho, Pf1, Pf2, numel(g1), Pf1/PF_MC, Pf2/PF_MC, numel(g2));
    end
end

%% does the tie-break kill the bimodality?
fprintf('\n########## bimodality test: 6 seeds, rho0 = 0.7 ##########\n');
fprintf('%8s %16s %16s\n','seed','orig Pf_sys','tiebreak Pf_sys');
P1 = []; P2 = [];
for seed = [42 1 2 3 7 123]
    rng(seed);
    R = systemReliabilityFn(nodes, members, kinematic, sections, rvSpec, ...
                            struct('eta',0,'rho0',0.7,'verbose',false));
    [~, a] = pnetSystemReliabilityFn(R.betaTilde, R.alphaTilde, 0.7);
    [~, b] = pnetTieBreakFn(R.betaTilde, R.alphaTilde, 0.7);
    P1(end+1) = a; P2(end+1) = b; %#ok<AGROW>
    fprintf('%8d %16.8e %16.8e\n', seed, a, b);
end
fprintf('\norig     : spread %.2f %% of mean\n', 100*(max(P1)-min(P1))/mean(P1));
fprintf('tiebreak : spread %.2f %% of mean\n', 100*(max(P2)-min(P2))/mean(P2));
fprintf('\nMC target: %.6e  CI [%.6e %.6e]\n', PF_MC, CI(1), CI(2));
