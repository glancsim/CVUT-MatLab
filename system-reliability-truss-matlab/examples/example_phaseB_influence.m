% example_phaseB_influence.m
%
% Demonstrates reducedStructureInfluenceFn (Phase B) on a small statically
% indeterminate Warren-type truss with 2 extra counter-diagonals (redundant
% bracing), giving gH > 0.
%
% Checks:
%   1. Intact structure: b_ij (axial force per member per unit load) is
%      computed and finite for every member.
%   2. Removing ONE redundant member still gives a solvable (non-singular)
%      reduced structure -> finite b_ij.
%   3. Removing a full minimal cut-set (found via nullSpaceCutSetsFn) turns
%      the truss into a mechanism -> the reduced stiffness matrix is
%      singular/near-singular -> MATLAB's backslash warns (rank deficient
%      / RCOND). This warning, not necessarily Inf/NaN in the result (\
%      returns a finite but physically meaningless least-squares-like
%      answer for singular systems), is the reliable "mechanism" signal
%      (metodika.md section 6) and is deliberately not suppressed by
%      reducedStructureInfluenceFn.
%   4. forceUnitResidual (a_il): unit self-equilibrated pull along a
%      member's own axis, applied on the structure with that member
%      removed.
%
% (c) S. Glanc, 2026

clear; close all;
srcDir = fullfile(fileparts(mfilename('fullpath')), '..', 'src');
femDir = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'fem-2d-truss-matlab', 'src');
addpath(srcDir); addpath(femDir);

%% Geometry: Warren truss (bottom 1-4, top 5-7) + 2 counter-diagonals
nodes.x = [0; 2; 4; 6;  1; 3; 5];
nodes.z = [0; 0; 0; 0;  1.5; 1.5; 1.5];

kinematic.x.nodes = [1];
kinematic.z.nodes = [1; 4];

sections.A = 1e-3;    % [m^2]
sections.E = 210e9;   % [Pa]

% 1: bottom 1-2   2: bottom 2-3   3: bottom 3-4
% 4: top 5-6      5: top 6-7
% 6: diag 1-5     7: diag 5-2     8: diag 2-6
% 9: diag 6-3     10: diag 3-7    11: diag 7-4  (closes the Warren chain
%                                   at node 4 — omitting it leaves node 4
%                                   with a single member, a mechanism)
% 12: counter-diag 2-5 (redundant, panel A)
% 13: counter-diag 3-6 (redundant, panel B)
members.nodesHead = [1;2;3;  5;6;  1;5;2;6;3;7;   2;3];
members.nodesEnd  = [2;3;4;  6;7;  5;2;6;3;7;4;   5;6];
members.nmembers  = numel(members.nodesHead);
members.sections  = ones(members.nmembers, 1);

fprintf('=== Phase B demo: reducedStructureInfluenceFn ===\n');
fprintf('nmembers = %d\n', members.nmembers);

%% Confirm indeterminacy via Phase A tools
A_eq = equilibriumMatrixFn(nodes, members, kinematic);
[cutSets, gH, ~] = nullSpaceCutSetsFn(A_eq);
fprintf('gH (degree of static indeterminacy) = %d\n', gH);
fprintf('minimal cut-sets = %s\n\n', strjoin(cellfun(@mat2str, cutSets, 'UniformOutput', false), ', '));

%% 1. Intact structure: unit vertical load at node 6 (top)
loads.x.nodes = []; loads.x.value = [];
loads.z.nodes = 6;  loads.z.value = -1;   % unit downward load

[b_ij, ~] = reducedStructureInfluenceFn(nodes, members, kinematic, sections, [], {loads}, []);
fprintf('1. Intact structure, unit downward load at node 6:\n');
fprintf('   b_i1 (axial force per member) = %s\n', mat2str(b_ij(:,1)', 4));
fprintf('   all finite: %d\n\n', all(isfinite(b_ij(:,1))));

% Equilibrium sanity: total vertical reaction must equal the applied load.
% Reactions = fixed-DOF entries of K*u - f_applied; simplest direct check:
% sum of member vertical force components at the two z-fixed nodes (1,4)
% should balance the unit load (Newton's third law on isolated supports).
[displacements, endForces] = linearSolverFn(sections, nodes, kinematic, members, loads); %#ok<ASGLU>
Nforces = endForces.local(1, :);
Rz = 0;
for m = 1:members.nmembers
    hn = members.nodesHead(m); en = members.nodesEnd(m);
    dz = nodes.z(en) - nodes.z(hn);
    L  = sqrt((nodes.x(en)-nodes.x(hn))^2 + dz^2);
    if ismember(hn, [1;4])
        Rz = Rz - Nforces(m) * dz / L;   % force member exerts ON the support node
    end
    if ismember(en, [1;4])
        Rz = Rz + Nforces(m) * dz / L;
    end
end
fprintf('   Reaction check: sum(Rz) + P_applied ~= 0 -> residual = %.3e (should be ~0)\n\n', Rz + (-1));

%% 2. Remove ONE redundant counter-diagonal -> still solvable
removed1 = 12;   % counter-diagonal, panel A — redundant bracing
[b_ij_r1, ~] = reducedStructureInfluenceFn(nodes, members, kinematic, sections, removed1, {loads}, []);
remaining1 = setdiff(1:members.nmembers, removed1);
fprintf('2. Removed member %d (one redundant): all remaining b_ij finite = %d\n\n', ...
    removed1, all(isfinite(b_ij_r1(remaining1, 1))));

%% 3. Remove a minimal cut-set -> mechanism (expect warning)
% {7,12} is a genuine minimal cut-set found by nullSpaceCutSetsFn above
% (neither member alone is necessary — both must go together).
removedMech = [7, 12];
fprintf('3. Removing minimal cut-set {%s} — a rank-deficiency warning below is EXPECTED:\n', ...
    num2str(removedMech));
[b_ij_mech, ~] = reducedStructureInfluenceFn(nodes, members, kinematic, sections, removedMech, {loads}, []); %#ok<ASGLU>
fprintf(['   (the warning IS the mechanism signal — MATLAB''s backslash on a\n' ...
         '    singular/near-singular K still returns a finite but physically\n' ...
         '    meaningless least-squares-like result, so callers must check\n' ...
         '    for the warning/RCOND, not just for Inf/NaN in b_ij.)\n\n']);

%% 4. forceUnitResidual — self-equilibrated unit pull along member 12's axis
residualList = 12;
removedForResidual = 12;   % member 12 itself excluded ("already failed")
[~, aResid] = reducedStructureInfluenceFn(nodes, members, kinematic, sections, removedForResidual, {}, residualList);
fprintf('4. Unit residual pull along member 12''s original axis (member 12 removed):\n');
fprintf('   a_i1 = %s\n', mat2str(aResid(:,1)', 4));
fprintf('   (self-equilibrated pair -> no net external load; forces are the pure\n');
fprintf('    redistribution response of the reduced structure to member 12''s pull.)\n');
