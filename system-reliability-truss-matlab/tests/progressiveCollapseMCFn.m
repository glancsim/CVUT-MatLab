function [beta_MC, results] = progressiveCollapseMCFn(nodes, members, kinematic, sections, rvSpec, nSamples, opts)
% progressiveCollapseMCFn  Brute-force progressive-collapse Monte Carlo --
% an INDEPENDENT oracle for systemReliabilityFn, with NO null-space/PNET/
% Cornell-index approximation (metodika.md section 6).
%
% For each of nSamples independent draws of the underlying RVs (member
% resistances by type, loads):
%   1. Solve FEM (linearSolverFn) on the current (progressively reduced)
%      structure under the sampled loads.
%   2. g_i = R_i - |N_i| for every surviving member; find min_i g_i.
%   3. If min g_i <= 0: that member "fails" -- brittle (eta=0): remove it
%      (zero stiffness contribution, exclude from the member list) and
%      loop back to 1 with the reduced structure. (eta>0 ductile is NOT
%      implemented here -- brittle only, matching the systemReliabilityFn
%      validation target; see metodika.md sec.6 for the ductile extension.)
%   4. Detect mechanism: after removing a member, check
%      rank(equilibriumMatrixFn(reduced)) < N (free DOFs). If mechanism:
%      this sample = SYSTEM FAILURE. Otherwise go to 1.
%   5. If no member fails (min g_i > 0): sample survives (censored at the
%      first FEM state -- a truss that never loses a member trivially
%      cannot become a mechanism, so no further looping needed).
%
% beta_MC = -norminv(nFail/nSamples).
%
% INPUTS:
%   nodes, members, kinematic, sections - full truss (fem-2d-truss-matlab convention)
%   rvSpec    - same struct as sequenceLimitStateFn/systemReliabilityFn:
%       .resGroup, .resMean, .resStd (Gaussian R per group, shared by type)
%       .loadCases, .loadMean, .loadStd (Gaussian load multipliers, independent)
%   nSamples  - number of MC samples (modest, e.g. 1e4-1e5 -- this is a
%               sanity cross-check, not a paper-grade 1e7 estimate)
%   opts      - (struct, optional): .verbose (default true), .seed (rng seed)
%
% OUTPUTS:
%   beta_MC - (scalar) Monte Carlo reliability index
%   results - (struct): .Pf_MC, .nFail, .nSamples, .failSequences (cell,
%             the member-removal order for each FAILED sample, for
%             diagnostic comparison against systemReliabilityFn.repSequence)
%
% See also: systemReliabilityFn, equilibriumMatrixFn
%
% (c) S. Glanc, 2026

if nargin < 7, opts = struct(); end
if ~isfield(opts, 'verbose'), opts.verbose = true; end
if isfield(opts, 'seed'), rng(opts.seed); end

nmembers = members.nmembers;
if isempty(nmembers), nmembers = numel(members.nodesHead); end

nGroups = numel(rvSpec.resMean);
nLoads  = numel(rvSpec.loadCases);

% Sample underlying standard normals, convert to physical RVs
U_R = randn(nSamples, nGroups);
U_P = randn(nSamples, nLoads);

R_samples = rvSpec.resMean(:)' + U_R .* rvSpec.resStd(:)';     % (nSamples x nGroups)
P_samples = rvSpec.loadMean(:)' + U_P .* rvSpec.loadStd(:)';   % (nSamples x nLoads)

nFail = 0;
failSequences = {};

if opts.verbose
    fprintf('progressiveCollapseMCFn: %d samples ...\n', nSamples);
end

for s = 1:nSamples
    R_type = R_samples(s, :)';        % (nGroups x 1)
    Pvals  = P_samples(s, :)';        % (nLoads x 1)

    Rmember = R_type(rvSpec.resGroup);   % (nmembers x 1) -- expand by type

    loadsCombined = combineLoadCases(rvSpec.loadCases, Pvals);

    survivors = true(nmembers, 1);
    sequence  = [];
    isSystemFailure = false;

    while true
        keepIdx = find(survivors);
        if numel(keepIdx) < nmembers && numel(keepIdx) > 0
            % check mechanism via rank of reduced equilibrium matrix
            membersRed.nodesHead = members.nodesHead(keepIdx);
            membersRed.nodesEnd  = members.nodesEnd(keepIdx);
            membersRed.nmembers  = numel(keepIdx);
            Ared = equilibriumMatrixFn(nodes, membersRed, kinematic);
            N_free = size(Ared, 1);
            if rank(Ared) < N_free
                isSystemFailure = true;
                break;
            end
        end
        if isempty(keepIdx)
            isSystemFailure = true;
            break;
        end

        membersRed.nodesHead = members.nodesHead(keepIdx);
        membersRed.nodesEnd  = members.nodesEnd(keepIdx);
        membersRed.sections  = members.sections(keepIdx);
        membersRed.nmembers  = numel(keepIdx);

        [~, endForces] = linearSolverFn(sections, nodes, kinematic, membersRed, loadsCombined);
        N_red = endForces.local(1, :)';    % (numel(keepIdx) x 1)

        g_red = Rmember(keepIdx) - abs(N_red);
        [gmin, localIdx] = min(g_red);

        if gmin > 0
            break;   % no more failures -- sample survives
        end

        failedMember = keepIdx(localIdx);
        survivors(failedMember) = false;
        sequence(end+1) = failedMember; %#ok<AGROW>
    end

    if isSystemFailure
        nFail = nFail + 1;
        failSequences{end+1} = sequence; %#ok<AGROW>
    end

    if opts.verbose && mod(s, max(1,round(nSamples/10))) == 0
        fprintf('  ... %d / %d samples (nFail so far = %d)\n', s, nSamples, nFail);
    end
end

Pf_MC = nFail / nSamples;
if Pf_MC <= 0
    beta_MC = Inf;
elseif Pf_MC >= 1
    beta_MC = -Inf;
else
    beta_MC = -norminv(Pf_MC);
end

results.Pf_MC   = Pf_MC;
results.nFail   = nFail;
results.nSamples = nSamples;
results.failSequences = failSequences;

if opts.verbose
    fprintf('progressiveCollapseMCFn: nFail = %d / %d, Pf_MC = %.4e, beta_MC = %.4f\n', ...
        nFail, nSamples, Pf_MC, beta_MC);
end

end

%--------------------------------------------------------------------------
function loadsOut = combineLoadCases(loadCases, weights)
xNodes = []; xVals = []; zNodes = []; zVals = [];
for j = 1:numel(loadCases)
    w = weights(j);
    if ~isempty(loadCases{j}.x.nodes)
        xNodes = [xNodes; loadCases{j}.x.nodes(:)]; %#ok<AGROW>
        xVals  = [xVals;  w * loadCases{j}.x.value(:)]; %#ok<AGROW>
    end
    if ~isempty(loadCases{j}.z.nodes)
        zNodes = [zNodes; loadCases{j}.z.nodes(:)]; %#ok<AGROW>
        zVals  = [zVals;  w * loadCases{j}.z.value(:)]; %#ok<AGROW>
    end
end
loadsOut.x.nodes = xNodes; loadsOut.x.value = xVals;
loadsOut.z.nodes = zNodes; loadsOut.z.value = zVals;
end
