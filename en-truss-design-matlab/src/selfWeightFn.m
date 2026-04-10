function sw = selfWeightFn(members, nodes, sections)
% selfWeightFn  Compute actual self-weight nodal forces from member properties.
%
% For each member:  W = rho * A * L * g   (rho = 7850 kg/m3, g = 9.81 m/s2)
% Distributed 50/50 to head and end nodes as downward vertical forces.
%
% INPUTS:
%   members  - struct: .nodesHead, .nodesEnd, .sections
%   nodes    - struct: .x, .z
%   sections - struct: .A (per section group)
%
% OUTPUTS:
%   sw - struct:
%     .nodes     (k x 1)  node indices with non-zero self-weight
%     .values    (k x 1)  vertical force [N] (negative = downward)
%     .total_kN  scalar   total self-weight of truss [kN]
%
% (c) S. Glanc, 2026

rho   = 7850;   % [kg/m3] steel density
g_acc = 9.81;   % [m/s2]

nnodes   = numel(nodes.x);
nmembers = numel(members.nodesHead);
F = zeros(nnodes, 1);   % accumulated nodal forces [N]

for p = 1:nmembers
    h  = members.nodesHead(p);
    e  = members.nodesEnd(p);
    dx = nodes.x(e) - nodes.x(h);
    dz = nodes.z(e) - nodes.z(h);
    Lp = sqrt(dx^2 + dz^2);
    Wp = rho * sections.A(members.sections(p)) * Lp * g_acc;
    F(h) = F(h) - Wp / 2;
    F(e) = F(e) - Wp / 2;
end

mask = F ~= 0;
sw.nodes    = find(mask);
sw.values   = F(mask);
sw.total_kN = -sum(F) / 1e3;

end
