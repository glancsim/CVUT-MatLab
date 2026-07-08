function seq = sequenceLimitStateFn(nodes, members, kinematic, sections, sequence, rvSpec, eta)
% sequenceLimitStateFn  Linearized limit-state coefficients for every
% element of an ORDERED failure sequence (metodika.md section 3, eq. 14 /
% Wei & Deng eq. 36).
%
%   g_i = R_i - sign(N_i) * ( sum_j b_ij*P_j + sum_{l<i} a_il*eta_l*R_l )
%
% where b_ij/a_il come from reducedStructureInfluenceFn on the structure
% with sequence(1:pos-1) already removed. R_i are resistance RVs SHARED by
% cross-section type (rvSpec.resGroup), P_j are independent load RVs
% (rvSpec.loads). Both are expressed here as R_i = muR + sigR*U_g(i),
% P_j = muP + sigP*U_j so every g_i comes out an EXACT linear combination
% of one common standardized-Gaussian vector U — this is what makes the
% Cornell/PNET machinery (cornellIndexFn) applicable at all.
%
% eta=0 (default, BRITTLE model): the sum_{l<i} a_il*eta_l*R_l term
% vanishes identically (Wei & Deng's own two worked examples never use
% ductile redistribution — see metodika.md "Key simplification" note /
% coordinator brief). With eta=0 forceUnitResidual (a_il) is not even
% computed — only b_ij (via reducedStructureInfluenceFn with
% residualMemberList=[]), matching Wei & Deng eq. 36 M_i = R_i - S_i
% exactly. Pass eta>0 (scalar or per-member vector) to enable the
% ductile/ redistribution pathway; NOT numerically validated against any
% reference example (no source example in metodika.md uses eta>0) — use
% with care.
%
% INPUTS:
%   nodes, members, kinematic, sections - full (un-reduced) truss
%   sequence - (1 x m) ordered member indices, sequence(1) fails first
%   rvSpec   - (struct) random-variable specification:
%     .resGroup    - (nmembers x 1) integer group id per member (members
%                    sharing a cross-section TYPE share the same group id
%                    -> same underlying RV, rho=1 within a group)
%     .resMean     - (nGroups x 1) mean resistance R [force units] per group
%     .resStd      - (nGroups x 1) std of R per group
%     .loadCases   - (1 x nLoads) cell array of UNIT `loads` structs
%                    (fem-2d-truss-matlab format, same convention as
%                    reducedStructureInfluenceFn's loadCases argument)
%     .loadMean    - (nLoads x 1) mean of each load multiplier P_j
%     .loadStd     - (nLoads x 1) std of each load multiplier P_j
%   eta      - (scalar or nmembers x 1, default 0) ductile residual-force
%              fraction per member (see above)
%
% OUTPUT: seq - (1 x m) struct array, one entry per sequence position, with:
%     .member     - original member index
%     .b          - (1 x nLoads) influence coeffs b_ij on the structure
%                   reduced by sequence(1:pos-1)
%     .a          - (1 x pos-1) influence coeffs a_il (empty if eta==0)
%                   for l = sequence(1:pos-1), same order
%     .signN      - sign(N_i) used (from the MEAN/nominal load case on the
%                   structure reduced by sequence(1:pos-1) -- see below)
%     .coeffU      - (1 x nU) row of sensitivities to the FULL shared U
%                   vector (nU = nGroups + nLoads), ready for cornellIndexFn
%                   after standardization (see sequenceToCornellFn below /
%                   mostProbableSequenceFn)
%     .meanG, .varG - mean and variance of g_i (computed directly, not by
%                   resumming coeffU, though they must and do agree)
%
% SIGN CONVENTION FOR sign(N_i): computed from the MEAN load case (every
% P_j set to its mean) evaluated on the structure reduced by
% sequence(1:pos-1) -- i.e. one extra FEM solve per position using
% reducedStructureInfluenceFn's loadCases mechanism with a single combined
% "mean" load case built by superposing rvSpec.loadCases weighted by
% rvSpec.loadMean. This is a modelling judgment call (documented per the
% task brief): the alternative (sign of b_ij for a representative single
% unit load) is ambiguous when multiple independent loads act together,
% whereas the mean combined load case is unambiguous and physically the
% "expected" loading direction. Flagged for coordinator sanity check.
%
% U VECTOR LAYOUT (shared across the whole sequence and across sequences
% from a call site's perspective -- callers must reuse the SAME rvSpec for
% every sequence/cut-set being compared): U = [U_R(1..nGroups), U_P(1..nLoads)],
% i.e. resistance-group slots first, then load slots, both standardized
% N(0,1).
%
% See also: reducedStructureInfluenceFn, cornellIndexFn, mostProbableSequenceFn
%
% (c) S. Glanc, 2026

if nargin < 7 || isempty(eta), eta = 0; end

nmembers = members.nmembers;
if isempty(nmembers), nmembers = numel(members.nodesHead); end
if isscalar(eta), eta = eta * ones(nmembers, 1); end

nLoads  = numel(rvSpec.loadCases);
nGroups = numel(rvSpec.resMean);
nU      = nGroups + nLoads;

m = numel(sequence);
seq = repmat(struct('member', [], 'b', [], 'a', [], 'signN', [], ...
    'coeffU', [], 'meanG', [], 'varG', []), 1, m);

% Combined mean load case (superposition of unit cases weighted by mean)
% -- used only to determine sign(N_i), see header comment.
meanLoads = combineLoadCasesFn(rvSpec.loadCases, rvSpec.loadMean);

for pos = 1:m
    i = sequence(pos);
    removedSoFar = sequence(1:pos-1);

    residualList = [];
    if any(eta(sequence(1:max(pos-1,0))) ~= 0)
        residualList = removedSoFar;
    end

    [b_ij, a_il] = reducedStructureInfluenceFn(nodes, members, kinematic, ...
        sections, removedSoFar, rvSpec.loadCases, residualList);

    b_i = b_ij(i, :);                 % (1 x nLoads)

    % sign(N_i) from the mean combined load case on the SAME reduced structure
    N_mean = linearSolverFnOnReduced(nodes, members, kinematic, sections, removedSoFar, meanLoads);
    N_i_mean = N_mean(i);
    signN = sign(N_i_mean);
    if signN == 0, signN = 1; end     % degenerate zero-force member -> arbitrary, doesn't affect g_i's mean sign meaningfully

    g = rvSpec.resGroup(i);

    coeffU = zeros(1, nU);
    coeffU(g) = coeffU(g) + rvSpec.resStd(g);          % dR_i/dU_g(i) = resStd
    coeffU(nGroups + (1:nLoads)) = coeffU(nGroups + (1:nLoads)) ...
        - signN * (b_i .* rvSpec.loadStd(:)');          % -signN*b_ij*sigP_j

    meanG = rvSpec.resMean(g) - signN * sum(b_i(:) .* rvSpec.loadMean(:));

    aRow = zeros(1, pos - 1);
    if ~isempty(residualList)
        for lk = 1:numel(removedSoFar)
            l  = removedSoFar(lk);
            gl = rvSpec.resGroup(l);
            a_il_val = a_il(i, lk);
            aRow(lk) = a_il_val;
            contrib  = eta(l) * a_il_val;
            coeffU(gl) = coeffU(gl) - signN * contrib * rvSpec.resStd(gl);
            meanG = meanG - signN * contrib * rvSpec.resMean(gl);
        end
    end

    varG = sum(coeffU.^2);

    seq(pos).member = i;
    seq(pos).b      = b_i;
    seq(pos).a      = aRow;
    seq(pos).signN  = signN;
    seq(pos).coeffU = coeffU;
    seq(pos).meanG  = meanG;
    seq(pos).varG   = varG;
end

end

%--------------------------------------------------------------------------
function loadsOut = combineLoadCasesFn(loadCases, weights)
% Superpose unit `loads` structs with given scalar weights into ONE loads
% struct (fem-2d-truss-matlab format), summing contributions per node/DOF.
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

%--------------------------------------------------------------------------
function N = linearSolverFnOnReduced(nodes, members, kinematic, sections, removedMembers, loads)
% Thin wrapper: solve the reduced structure (member indices with
% removedMembers excluded) under `loads`, return (nmembers x 1) axial
% forces with NaN for removed members -- mirrors reducedStructureInfluenceFn's
% own reduction logic exactly (kept in sync deliberately, duplicated here
% rather than modifying that function per the task's "do not touch Phase B" rule).
nmembers = members.nmembers;
if isempty(nmembers), nmembers = numel(members.nodesHead); end
removedMembers = unique(removedMembers(:)');
keepMask = true(nmembers, 1);
keepMask(removedMembers) = false;
keepIdx = find(keepMask);

membersRed.nodesHead = members.nodesHead(keepIdx);
membersRed.nodesEnd  = members.nodesEnd(keepIdx);
membersRed.sections  = members.sections(keepIdx);
membersRed.nmembers  = numel(keepIdx);

[~, endForces] = linearSolverFn(sections, nodes, kinematic, membersRed, loads);
N = nan(nmembers, 1);
N(keepIdx) = endForces.local(1, :)';
end
