function vertex = memberVertexFn(members, nodes)
% memberVertexFn  Compute direction vectors [Δx, Δz] for each truss member.
%
% INPUTS:
%   members.nodesHead, members.nodesEnd  - node indices (nmembers x 1)
%   nodes.x, nodes.z                     - node coordinates (nnodes x 1)
%
% OUTPUT:
%   vertex  - (nmembers x 2)  [Δx, Δz] = end - head position
%
% (c) S. Glanc, 2025

n = members.nmembers;
vertex = zeros(n, 2);
for p = 1:n
    h = members.nodesHead(p);
    e = members.nodesEnd(p);
    vertex(p, 1) = nodes.x(e) - nodes.x(h);  % Δx
    vertex(p, 2) = nodes.z(e) - nodes.z(h);  % Δz
end
end
