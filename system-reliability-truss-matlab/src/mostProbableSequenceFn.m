function [bestSeq, bestBetaP, allBetaP, allPerms] = mostProbableSequenceFn( ...
    nodes, members, kinematic, sections, cutSet, rvSpec, eta)
% mostProbableSequenceFn  Representative (lowest-beta_p) failure mode of a
% minimal cut-set (metodika.md section 4: "the one with the lowest beta_p
% in those failure modes corresponding to the same minimal cut set can be
% determined").
%
% Brute-forces all permutations of `cutSet` (all possible failure orders)
% and returns the one with the lowest sequence reliability index beta_p
% (via cornellIndexFn).
%
% PERFORMANCE -- eta=0 FAST PATH (memoized): metodika.md's "Modelovaci
% rozhodnuti: eta=0" note shows that with eta=0 (this project's standing
% default, and the ONLY model validated against a reference example) the
% limit-state coefficients (coeffU/meanG/varG) at sequence position `pos`
% depend ONLY on the SET {sequence(1:pos-1)} of already-removed members,
% NOT on their order -- because the only order-dependent piece
% (sum_{l<i} a_il*eta_l*R_l) identically vanishes when eta=0. The naive
% per-permutation call to sequenceLimitStateFn therefore recomputes
% reducedStructureInfluenceFn (a FEM solve) k!*k times for a cut-set of
% size k, even though only 2^k-1 distinct removed-SETS actually occur
% across all k! permutations. This function memoizes the FEM part
% (b_ij, N_mean for ALL members at once, one cache entry per removed-set)
% in a containers.Map keyed by the sorted removed-set, cutting the number
% of FEM-heavy calls from k!*k to 2^k-1 (k=4: 96->15, ~6x; k=5: 600->31,
% ~19x; k=8: 322560->255, >1000x -- this is exactly the parameter, cut-set
% size tied to gH, that made the earlier 4-panel/21-member Warren X-brace
% attempt impractically slow, see example_warren_xbrace.m header).
%
% The per-member coeffU/meanG/varG assembly in the fast path DELIBERATELY
% duplicates sequenceLimitStateFn.m's eta=0 loop body (local subfunctions
% below) rather than modifying that already-validated function -- same
% "keep in sync, don't touch Phase B/C" convention already used by
% reducedStructureInfluenceFn.m's own sequenceLimitStateFn-local
% linearSolverFnOnReduced helper. Keep the two in sync if either changes.
%
% eta~=0 on any member of THIS cut-set: falls back to the original,
% unoptimized per-permutation sequenceLimitStateFn call -- the eta>0
% residual-redistribution term IS order-dependent, so the cache above is
% not valid there. That path is also unvalidated against any reference
% example (metodika.md), so it is left untouched on purpose.
%
% INPUTS:
%   nodes, members, kinematic, sections, rvSpec, eta - see sequenceLimitStateFn
%   cutSet - (1 x k) unordered minimal cut-set (member indices)
%
% OUTPUTS:
%   bestSeq   - (1 x k) the permutation of cutSet with lowest beta_p
%   bestBetaP - (scalar) that beta_p
%   allBetaP  - (nPerms x 1) beta_p for every permutation tried
%   allPerms  - (nPerms x k) the permutations tried (rows), same order as allBetaP
%
% See also: sequenceLimitStateFn, cornellIndexFn, equivalentPlaneFn
%
% (c) S. Glanc, 2026

if nargin < 7, eta = 0; end

cutSet   = cutSet(:)';
k        = numel(cutSet);
allPerms = perms(cutSet);          % (k! x k)
nPerms   = size(allPerms, 1);
allBetaP = zeros(nPerms, 1);

nmembers = members.nmembers;
if isempty(nmembers), nmembers = numel(members.nodesHead); end
if isscalar(eta), etaVec = eta * ones(nmembers, 1); else, etaVec = eta(:); end
etaIsZeroOnCutSet = ~any(etaVec(cutSet) ~= 0);

if etaIsZeroOnCutSet
    % --- Fast path: memoized eta=0 (see header) -----------------------
    nLoads  = numel(rvSpec.loadCases);
    nGroups = numel(rvSpec.resMean);
    nU      = nGroups + nLoads;
    meanLoads = combineLoadCasesForCacheFn(rvSpec.loadCases, rvSpec.loadMean);

    cacheMap = containers.Map('KeyType', 'char', 'ValueType', 'any');

    for p = 1:nPerms
        seqMembers = allPerms(p, :);
        alpha   = zeros(k, nU);
        betaVec = zeros(k, 1);
        for pos = 1:k
            i = seqMembers(pos);
            removedSoFar = seqMembers(1:pos-1);
            [b_ij, N_mean] = getReducedStateFn(cacheMap, nodes, members, kinematic, ...
                sections, removedSoFar, rvSpec.loadCases, meanLoads);

            b_i = b_ij(i, :);
            signN = sign(N_mean(i));
            if signN == 0, signN = 1; end

            g = rvSpec.resGroup(i);
            coeffU = zeros(1, nU);
            coeffU(g) = coeffU(g) + rvSpec.resStd(g);
            coeffU(nGroups + (1:nLoads)) = coeffU(nGroups + (1:nLoads)) ...
                - signN * (b_i .* rvSpec.loadStd(:)');
            meanG = rvSpec.resMean(g) - signN * sum(b_i(:) .* rvSpec.loadMean(:));
            varG  = sum(coeffU.^2);

            sd = sqrt(varG);
            alpha(pos, :) = -coeffU / sd;
            betaVec(pos)  = meanG / sd;
        end
        allBetaP(p) = cornellIndexFn(alpha, betaVec);
    end
else
    % --- Fallback: original unoptimized path (eta ~= 0 on this cut-set) ---
    for p = 1:nPerms
        seq = sequenceLimitStateFn(nodes, members, kinematic, sections, allPerms(p, :), rvSpec, eta);
        kk = numel(seq);
        alpha = zeros(kk, size(seq(1).coeffU, 2));
        betaVec = zeros(kk, 1);
        for i = 1:kk
            sd = sqrt(seq(i).varG);
            alpha(i, :) = -seq(i).coeffU / sd;
            betaVec(i)  = seq(i).meanG / sd;
        end
        allBetaP(p) = cornellIndexFn(alpha, betaVec);
    end
end

[bestBetaP, idx] = min(allBetaP);
bestSeq = allPerms(idx, :);

end

%--------------------------------------------------------------------------
function [b_ij, N_mean] = getReducedStateFn(cacheMap, nodes, members, kinematic, ...
    sections, removedSoFar, loadCases, meanLoads)
% Memoized (b_ij, N_mean) for ALL members at once, keyed by the SORTED
% removed-member set (order-independent -- valid only because the caller
% has already confirmed eta=0 on this cut-set, see mostProbableSequenceFn
% header). Bundles the mean combined load case as one extra load case
% into the SAME reducedStructureInfluenceFn call that computes b_ij (that
% function does not care whether a load case is "unit" or not -- it is
% just a linear FEM solve), so each cache MISS costs exactly one
% reducedStructureInfluenceFn call (nLoads+1 FEM solves) instead of two
% separate calls (as sequenceLimitStateFn.m does per-position).
key = mat2str(sort(removedSoFar(:)'));
if isKey(cacheMap, key)
    cached = cacheMap(key);
    b_ij   = cached.b_ij;
    N_mean = cached.N_mean;
    return;
end

[b_ext, ~] = reducedStructureInfluenceFn(nodes, members, kinematic, sections, ...
    removedSoFar, [loadCases, {meanLoads}], []);
nLoads = numel(loadCases);
b_ij   = b_ext(:, 1:nLoads);
N_mean = b_ext(:, nLoads + 1);

cacheMap(key) = struct('b_ij', b_ij, 'N_mean', N_mean); %#ok<NASGU>
end

%--------------------------------------------------------------------------
function loadsOut = combineLoadCasesForCacheFn(loadCases, weights)
% Superpose unit `loads` structs with given scalar weights into ONE loads
% struct (fem-2d-truss-matlab format) -- identical logic to
% sequenceLimitStateFn.m's private combineLoadCasesFn, duplicated here
% (that function is out of scope, private to its own file); keep the two
% in sync if either changes.
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
