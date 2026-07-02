function [b_ij, forceUnitResidual] = reducedStructureInfluenceFn( ...
    nodes, members, kinematic, sections, removedMembers, loadCases, residualMemberList)
% reducedStructureInfluenceFn  FEM redistribution coefficients b_ij, a_il
% for a truss with a subset of members already failed/removed.
%
% Implements the influence coefficients of metodika.md section 3 (eq. 14,
% Wei & Deng eq. 36) used by the (not-yet-implemented) failure-sequence
% limit state g_i(d,X) = S_i*A_i - sign(N_i)*(sum_j b_ij*P_j +
% sum_{l<i} a_il*eta_l*S_l*A_l). Both are FEM influence coefficients on the
% REDUCED structure (with removedMembers excluded from the stiffness), so
% this function does NOT depend on any RV/limit-state code — it is pure
% FEM, reused by Phase C for every failure-sequence position.
%
% INPUTS:
%   nodes, members, kinematic, sections - full (un-reduced) truss, same
%       format as fem-2d-truss-matlab/linearSolverFn.
%   removedMembers - row/col vector of ORIGINAL member indices to exclude
%       from the stiffness (already-failed members at this point in the
%       failure sequence). Use [] for the intact structure.
%   loadCases - cell array of `loads` structs (fem-2d-truss-matlab format),
%       each applied as a UNIT load case, e.g.:
%         loads.x.nodes=[]; loads.x.value=[];
%         loads.z.nodes=[5]; loads.z.value=[1];
%   residualMemberList - vector of ORIGINAL member indices `l` for which
%       to compute the unit self-equilibrated residual-force influence
%       a_il (eq. 14). Each `l` is applied as a unit tension pull between
%       its own head/end nodes on the structure with `removedMembers`
%       EXCLUDED (removedMembers should already include `l` itself when
%       calling this for a real failure-sequence step, since a_il is
%       defined as the effect of l's release AFTER l has failed).
%
% OUTPUTS:
%   b_ij - (nmembers x numel(loadCases)) axial force in every member per
%          unit application of load case j, on the structure with
%          removedMembers excluded. Rows corresponding to removedMembers
%          are set to NaN (member no longer exists — force undefined, NOT
%          zero, so callers don't silently mistake "removed" for "unloaded").
%   forceUnitResidual - (nmembers x numel(residualMemberList)) axial force
%          in every remaining member from a unit residual pull applied
%          along original member l's axis (eq. 14, a_il). Column order
%          matches residualMemberList. Rows for removedMembers = NaN, same
%          convention as b_ij.
%
% SIGN CONVENTION for the residual force pair (eq. 14): member l pulled
% its two end nodes together as it failed in tension (or apart in
% compression) up to the instant of failure; we apply a UNIT force at
% l's head node directed toward l's end node, and a unit force at l's end
% node directed toward l's head node — i.e. the same self-equilibrated
% pair member l itself would have exerted as an axial TENSION member.
% a_il is then linear in the actual residual force magnitude
% eta_l*S_l*A_l applied by the caller (Phase C), so the unit convention
% here is fixed regardless of the true sign of member l's force.
%
% NUMERICAL BEHAVIOR AT / BEYOND MECHANISM: once enough members are
% removed to turn the truss into a mechanism, the reduced stiffness
% matrix is singular/near-singular and MATLAB's backslash in
% linearSolverFn emits a rank-deficiency ("Matrix is close to singular",
% RCOND) warning — this warning is the RELIABLE mechanism signal per
% metodika.md section 6. Backslash on a singular system still returns a
% finite (but physically meaningless, least-squares-like) result rather
% than guaranteed Inf/NaN, so callers (Phase C) should NOT rely solely on
% isfinite(b_ij)/isfinite(a_il) to detect a mechanism — check for the
% warning (or independently test rank via equilibriumMatrixFn /
% nullSpaceCutSetsFn on the reduced member set) instead. This is
% intentionally NOT suppressed here.
%
% See also: equilibriumMatrixFn, nullSpaceCutSetsFn, linearSolverFn
%
% (c) S. Glanc, 2026

nmembers = members.nmembers;
if isempty(nmembers), nmembers = numel(members.nodesHead); end

removedMembers = unique(removedMembers(:)');
keepMask = true(nmembers, 1);
keepMask(removedMembers) = false;
keepIdx  = find(keepMask);          % original indices kept in the reduced structure

%--------------------------------------------------------------------------
% Build reduced members struct — original member numbering preserved via
% keepIdx (caller-facing outputs are re-expanded back to nmembers rows with
% NaN for removed members, see below), only the SOLVE uses the compacted
% (renumbered) struct fem-2d-truss-matlab requires.
%--------------------------------------------------------------------------
membersRed.nodesHead = members.nodesHead(keepIdx);
membersRed.nodesEnd  = members.nodesEnd(keepIdx);
membersRed.sections  = members.sections(keepIdx);
membersRed.nmembers  = numel(keepIdx);

%--------------------------------------------------------------------------
% b_ij — unit load cases on the reduced structure
%--------------------------------------------------------------------------
nLC = numel(loadCases);
b_ij = nan(nmembers, nLC);

for j = 1:nLC
    [~, endForces] = linearSolverFn(sections, nodes, kinematic, membersRed, loadCases{j});
    N = endForces.local(1, :)';          % (nRed x 1), tension positive
    b_ij(keepIdx, j) = N;
end

%--------------------------------------------------------------------------
% forceUnitResidual (a_il) — unit self-equilibrated tension pull along
% original member l's axis, applied on the SAME reduced structure passed
% in (removedMembers). Direction: force at head node points toward end
% node, force at end node points toward head node (member l's own
% tension convention), independent of whether l itself is in keepIdx —
% l is typically already excluded via removedMembers by the caller.
%--------------------------------------------------------------------------
nRes = numel(residualMemberList);
forceUnitResidual = nan(nmembers, nRes);

for k = 1:nRes
    l = residualMemberList(k);
    dx = nodes.x(members.nodesEnd(l)) - nodes.x(members.nodesHead(l));
    dz = nodes.z(members.nodesEnd(l)) - nodes.z(members.nodesHead(l));
    L  = sqrt(dx^2 + dz^2);
    ux = dx / L; uz = dz / L;

    loads_l.x.nodes = [members.nodesHead(l); members.nodesEnd(l)];
    loads_l.x.value = [ux; -ux];
    loads_l.z.nodes = [members.nodesHead(l); members.nodesEnd(l)];
    loads_l.z.value = [uz; -uz];

    [~, endForces] = linearSolverFn(sections, nodes, kinematic, membersRed, loads_l);
    N = endForces.local(1, :)';
    forceUnitResidual(keepIdx, k) = N;
end

end
