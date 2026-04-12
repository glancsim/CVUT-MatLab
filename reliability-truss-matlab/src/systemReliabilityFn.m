function results = systemReliabilityFn(nodes, members, sections, kinematic, loadParams, opts)
% systemReliabilityFn  Monte Carlo system reliability analysis via UQLab.
%
% Orchestrates the reliability analysis pipeline:
%   1. Pre-compute deterministic quantities (classification, L_cr, alpha)
%   2. Define random variables (UQLab input)
%   3. Define computational model (limit state function)
%   4. Configure and run Monte Carlo simulation
%   5. Extract and return results
%
% INPUTS:
%   nodes, members, sections, kinematic, loadParams — from trussHallInputFn
%   opts - (optional) struct with:
%     .nSamples      max MC samples (default: 1e6)
%     .batchSize     samples per batch (default: 1e4)
%     .method        'MCS' or 'SubsetSimulation' (default: 'MCS')
%     .rvOpts        struct passed to defineRandomVariablesFn
%     .verbose       logical (default: true)
%
% OUTPUTS:
%   results - struct with fields:
%     .Pf            probability of failure
%     .beta          reliability index = -norminv(Pf)
%     .Pf_CoV        coefficient of variation of Pf estimate
%     .nSamples      number of samples used
%     .nFailures     number of failure samples
%     .g_sys         (nSamples×1) system LSF evaluations
%     .beta_convergence  (nBatches×1) running beta estimate
%     .params        deterministic parameters struct (for post-processing)
%     .classification member classification
%     .Lcr           buckling lengths
%
% (c) S. Glanc, 2026

if nargin < 6, opts = struct(); end

if ~isfield(opts, 'nSamples'),  opts.nSamples  = 1e6;    end
if ~isfield(opts, 'batchSize'), opts.batchSize  = 1e4;    end
if ~isfield(opts, 'method'),    opts.method     = 'MCS';  end
if ~isfield(opts, 'rvOpts'),    opts.rvOpts     = struct(); end
if ~isfield(opts, 'verbose'),   opts.verbose    = true;   end

nmembers = numel(members.nodesHead);
nG       = loadParams.sectionGroups.nGroups;

%% 1. Pre-compute deterministic quantities --------------------------------
if opts.verbose, fprintf('=== Spolehlivostní analýza — Monte Carlo ===\n'); end

% Member classification
classification = memberClassificationFn(members, nodes);

% Buckling lengths
Lcr_struct = bucklingLengthsFn(members, nodes, classification, loadParams);
Lcr = Lcr_struct.governing;

% Imperfection factors per section group
alpha_imp = zeros(nG, 1);
for sg = 1:nG
    switch lower(sections.curve{sg})
        case 'a0', alpha_imp(sg) = 0.13;
        case 'a',  alpha_imp(sg) = 0.21;
        case 'b',  alpha_imp(sg) = 0.34;
        case 'c',  alpha_imp(sg) = 0.49;
        case 'd',  alpha_imp(sg) = 0.76;
    end
end

% Nominal wall thicknesses
t_nom = sections.t;

if opts.verbose
    fprintf('  Prutů: %d, průřezových skupin: %d\n', nmembers, nG);
    fprintf('  Metoda: %s, max vzorků: %.0e\n', opts.method, opts.nSamples);
end

%% 2. Define random variables (UQLab) ------------------------------------
InputOpts = defineRandomVariablesFn(loadParams, sections, opts.rvOpts);
myInput   = uq_createInput(InputOpts);

%% 3. Precompute influence coefficients (3 FEM solves) --------------------
if opts.verbose, fprintf('  Předpočítávám vlivové koeficienty (3× FEM) ...\n'); end

% Unit load vectors:
%   N_perm: G_P = 1, s_roof = 0, G_s = 0
%   N_snow: G_P = 0, s_roof = 1 kN/m², G_s = 0
%   N_sw:   G_P = 0, s_roof = 0, G_s = 1

loads_perm = reliabilityLoadsFn(loadParams, 0, 1, 0);     % unit permanent
[~, ef_perm] = linearSolverFn(sections, nodes, kinematic, members, loads_perm);
N_perm = ef_perm.local(1, :)';   % (nmem×1) [N]

loads_snow = reliabilityLoadsFn(loadParams, 0, 0, 1);     % unit snow (1 kN/m²)
[~, ef_snow] = linearSolverFn(sections, nodes, kinematic, members, loads_snow);
N_snow = ef_snow.local(1, :)';   % (nmem×1) [N]

% Self-weight unit: create loads with only sw component
loads_sw_only.x.nodes = [];  loads_sw_only.x.value = [];
loads_sw_only.z.nodes = loadParams.selfWeight.nodes;
loads_sw_only.z.value = loadParams.selfWeight.values;    % nominal [N]
[~, ef_sw] = linearSolverFn(sections, nodes, kinematic, members, loads_sw_only);
N_sw = ef_sw.local(1, :)';   % (nmem×1) [N]

if opts.verbose
    fprintf('  Vlivové koeficienty hotovy.\n');
end

%% 4. Build params struct for limitStateFastFn ----------------------------
lsParams.nGroups    = nG;
lsParams.nmembers   = nmembers;
lsParams.f_y_nom    = loadParams.f_y;
lsParams.s_k        = loadParams.s_k;
lsParams.t_nom      = t_nom;
lsParams.alpha_imp  = alpha_imp;
lsParams.Lcr        = Lcr;
lsParams.nodes      = nodes;
lsParams.members    = members;
lsParams.sections   = sections;
lsParams.kinematic  = kinematic;
lsParams.loadParams = loadParams;
lsParams.E          = loadParams.E;
lsParams.N_perm     = N_perm;
lsParams.N_snow     = N_snow;
lsParams.N_sw       = N_sw;

%% 5. Define computational model -----------------------------------------
limitStateFastFn('reset', []);

ModelOpts.mFile  = 'limitStateFastFn';
ModelOpts.Parameters = lsParams;
ModelOpts.isVectorized = true;    % fully vectorized
myModel = uq_createModel(ModelOpts);

%% 6. Configure reliability analysis -------------------------------------
AnalysisOpts.Type = 'Reliability';
AnalysisOpts.Method = opts.method;
AnalysisOpts.Simulation.MaxSampleSize = opts.nSamples;
AnalysisOpts.Simulation.BatchSize     = opts.batchSize;
AnalysisOpts.SaveEvaluations = true;

if opts.verbose
    fprintf('  Spouštím UQLab %s ...\n', opts.method);
    tic;
end

myAnalysis = uq_createAnalysis(AnalysisOpts);

if opts.verbose
    elapsed = toc;
    fprintf('  Dokončeno za %.1f s\n', elapsed);
end

%% 7. Extract results ----------------------------------------------------
uqResults = myAnalysis.Results;

results.Pf       = uqResults.Pf;
results.beta     = uqResults.Beta;
results.Pf_CoV   = uqResults.CoV;
results.nSamples = uqResults.ModelEvaluations;

% System LSF values
if isfield(uqResults, 'History')
    g_raw = uqResults.History.G;
    % UQLab Subset returns cell array of levels; MCS returns numeric array
    if iscell(g_raw)
        g_all = vertcat(g_raw{:});
    else
        g_all = g_raw;
    end
    results.g_sys = g_all;
    results.nFailures = sum(g_all <= 0);

    % Convergence: running Pf and beta per batch
    nBatch = opts.batchSize;
    nEval  = numel(g_all);
    nSteps = floor(nEval / nBatch);
    beta_conv = zeros(nSteps, 1);
    Pf_conv   = zeros(nSteps, 1);
    for ib = 1:nSteps
        g_sub = g_all(1:ib*nBatch);
        Pf_conv(ib) = mean(g_sub <= 0);
        if Pf_conv(ib) > 0
            beta_conv(ib) = -norminv(Pf_conv(ib));
        else
            beta_conv(ib) = Inf;
        end
    end
    results.beta_convergence = beta_conv;
    results.Pf_convergence   = Pf_conv;
    results.n_convergence    = (1:nSteps)' * nBatch;
else
    results.g_sys = [];
    results.nFailures = round(results.Pf * results.nSamples);
    results.beta_convergence = results.beta;
    results.Pf_convergence   = results.Pf;
    results.n_convergence    = results.nSamples;
end

results.params         = lsParams;
results.classification = classification;
results.Lcr            = Lcr_struct;
results.elapsed        = elapsed;

%% 8. Per-member results from persistent store ----------------------------
memberStore = limitStateFastFn('get_store', []);
if ~isempty(memberStore)
    nEval = size(memberStore.g_member, 1);

    % Per-member failure probability
    results.member.Pf = mean(memberStore.g_member <= 0, 1)';   % (nmembers×1)
    results.member.beta = zeros(nmembers, 1);
    for p = 1:nmembers
        if results.member.Pf(p) > 0
            results.member.beta(p) = -norminv(results.member.Pf(p));
        else
            results.member.beta(p) = Inf;
        end
    end

    % Critical member histogram: how often each member is the weakest link
    results.member.critical_count = histcounts(memberStore.critical_member, ...
        (0.5 : 1 : nmembers+0.5))';   % (nmembers×1)
    results.member.critical_pct = results.member.critical_count / nEval * 100;

    % Dominant failure mode per member (tension vs buckling)
    results.member.n_tension_fail  = sum(memberStore.fail_mode == 1, 1)';
    results.member.n_buckling_fail = sum(memberStore.fail_mode == 2, 1)';

    results.member.g_member = memberStore.g_member;
else
    results.member = struct();
end

%% 9. Print summary ------------------------------------------------------
if opts.verbose
    fprintf('\n── Výsledky ──────────────────────────────────\n');
    fprintf('  Pf     = %.3e\n', results.Pf);
    fprintf('  β      = %.3f\n', results.beta);
    fprintf('  CoV(Pf)= %.1f %%\n', results.Pf_CoV * 100);
    fprintf('  Vzorky = %.0e  (selhání: %d)\n', results.nSamples, results.nFailures);
    fprintf('  β_cíl  = 3.8  (CC2, 50 let)\n');
    if results.beta >= 3.8
        fprintf('  Stav:  VYHOVUJE (β ≥ 3.8)\n');
    else
        fprintf('  Stav:  NEVYHOVUJE (β < 3.8)\n');
    end
    fprintf('──────────────────────────────────────────────\n');

    % Per-member table
    if isfield(results, 'member') && isfield(results.member, 'Pf')
        fprintf('\n── Per-member spolehlivost ────────────────────\n');
        fprintf('  %4s  %-14s  %10s  %8s  %8s  %s\n', ...
            'č.', 'Typ', 'Pf_member', 'β_member', 'Krit.%', 'Mód');
        for p = 1:nmembers
            type_str = char(classification.type(p));
            if results.member.n_buckling_fail(p) > results.member.n_tension_fail(p)
                mode_str = 'vzpěr';
            elseif results.member.n_tension_fail(p) > 0
                mode_str = 'tah';
            else
                mode_str = '—';
            end
            if isinf(results.member.beta(p))
                beta_str = '   Inf';
            else
                beta_str = sprintf('%8.2f', results.member.beta(p));
            end
            fprintf('  %4d  %-14s  %10.2e  %s  %7.1f%%  %s\n', ...
                p, type_str, results.member.Pf(p), beta_str, ...
                results.member.critical_pct(p), mode_str);
        end
    end
end

end
