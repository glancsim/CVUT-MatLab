
%
% In: 
% 
%
% Out:
%  
%
% (c) S. Glanc, 2022


function [dofs]=nodesDofsNumbFn(nodes)
    [s,k] = size(nodes.dofs);
    m = 0;
    for g = 1:s
        for j = 1:k
            if nodes.dofs(g,j) == 1
                dofs(g,j) = nodes.dofs(g,j) + m;
                m = m+1;
            end
        end
    end
end