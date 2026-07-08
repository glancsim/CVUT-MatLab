function A = equilibriumMatrixFn(nodes, members, kinematic)
% equilibriumMatrixFn  Build the equilibrium matrix of a 2D pin-jointed truss.
%
% Wei & Deng (2022), eq. 1-6: A = [a_1, ..., a_nel], column k = unit direction
% vector of member k placed at its head/end free global DOF rows. This is the
% same geometric information used by fem-2d-truss-matlab/stiffnessMatrixFn to
% assemble K, just WITHOUT the EA/L stiffness weighting.
%
% INPUTS:
%   nodes     - (struct) .x, .z  (nnodes x 1) node coordinates
%   members   - (struct) .nodesHead, .nodesEnd (nmembers x 1), .nmembers
%   kinematic - (struct) .x.nodes, .z.nodes  (fixed-DOF node indices)
%
% OUTPUT:
%   A  - (N x nmembers) equilibrium matrix, N = number of free DOFs
%        (= max(codeNumbersFn(members, nodes)))
%
% Sign convention: column k has +[c,s] at the head-node DOF rows and
% -[c,s] at the end-node DOF rows (c,s = direction cosines head->end).
% This is an arbitrary but internally consistent choice of a_k (eq. 3) —
% flipping it for all columns simultaneously would not change rank/null
% space properties used downstream.
%
% See also: nullSpaceCutSetsFn, memberVertexFn, codeNumbersFn
%
% (c) S. Glanc, 2026

nnodes = numel(nodes.x);
nodes.dofs = true(nnodes, 2);
nodes.dofs(kinematic.x.nodes, 1) = false;
nodes.dofs(kinematic.z.nodes,  2) = false;
nodes.nnodes = nnodes;

members.nmembers = numel(members.nodesHead);
members.vertex      = memberVertexFn(members, nodes);
members.codeNumbers = codeNumbersFn(members, nodes);

N  = max(max(members.codeNumbers));
nm = members.nmembers;
A  = zeros(N, nm);

for k = 1:nm
    dx = members.vertex(k, 1);
    dz = members.vertex(k, 2);
    L  = sqrt(dx^2 + dz^2);
    c  = dx / L;
    s  = dz / L;

    codes = members.codeNumbers(k, :);   % [ux_head, uz_head, ux_end, uz_end]

    if codes(1) ~= 0, A(codes(1), k) = A(codes(1), k) + c; end
    if codes(2) ~= 0, A(codes(2), k) = A(codes(2), k) + s; end
    if codes(3) ~= 0, A(codes(3), k) = A(codes(3), k) - c; end
    if codes(4) ~= 0, A(codes(4), k) = A(codes(4), k) - s; end
end

end
