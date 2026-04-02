function codes = codeNumbersFn(beams, nodes)
% codeNumbersFn  Assign global DOF numbers to each beam end.
%
% Nodes have 3 DOFs: [ux, uz, ry].  Constrained DOFs (nodes.dofs == false)
% receive code number 0 and are excluded from the assembled system.
% Free DOFs are numbered sequentially 1 .. nodes.ndofs.
%
% INPUTS:
%   beams.nodesHead, .nodesEnd, .nbeams
%   nodes.dofs  - (nnodes x 3) logical: true = free, false = fixed
%
% OUTPUTS:
%   codes  - (nbeams x 6) global DOF numbers per beam
%            columns 1-3: head-node [ux, uz, ry]
%            columns 4-6: end-node  [ux, uz, ry]
%            0 = constrained DOF
%
% (c) S. Glanc, 2026

[s, k] = size(nodes.dofs);   % s = nnodes, k = 3
dofs   = zeros(s, k);
m      = 0;
for g = 1:s
    for j = 1:k
        if nodes.dofs(g, j)
            m        = m + 1;
            dofs(g, j) = m;
        end
    end
end

codes = zeros(beams.nbeams, 2*k);
for i = 1:beams.nbeams
    codes(i, 1:k)     = dofs(beams.nodesHead(i), :);
    codes(i, k+1:2*k) = dofs(beams.nodesEnd(i),  :);
end
end
