function codes = codeNumbersFn(members, nodes)
% codeNumbersFn  Assign global DOF code numbers to truss members.
%
% Each node has 2 DOFs: [ux, uz]. Free DOFs are numbered sequentially
% (1, 2, 3, ...). Constrained DOFs (nodes.dofs == false) receive code 0.
%
% INPUTS:
%   members.nodesHead, members.nodesEnd  - (nmembers x 1)
%   nodes.dofs  - (nnodes x 2) logical, true = free DOF
%   nodes.nnodes
%
% OUTPUT:
%   codes  - (nmembers x 4) global code numbers for each member
%            columns: [ux_head, uz_head, ux_end, uz_end]
%            0 = constrained DOF (not assembled)
%
% (c) S. Glanc, 2025

nnodes  = nodes.nnodes;
ndofpn  = 2;            % DOFs per node

% Build global DOF numbering: free DOFs only, sequentially
dofMap = zeros(nnodes, ndofpn);
counter = 0;
for n = 1:nnodes
    for d = 1:ndofpn
        if nodes.dofs(n, d)
            counter = counter + 1;
            dofMap(n, d) = counter;
        end
    end
end

% Assign code numbers per member (4 per member: 2 head + 2 end)
nm = members.nmembers;
codes = zeros(nm, 4);
for p = 1:nm
    h = members.nodesHead(p);
    e = members.nodesEnd(p);
    codes(p, 1:2) = dofMap(h, :);   % head node DOFs
    codes(p, 3:4) = dofMap(e, :);   % end  node DOFs
end
end
