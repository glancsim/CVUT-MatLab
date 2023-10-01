% Vytvoření kódových čísel
%
% In: 
%   beams - nosníky
%   nodes - uzlové informace
%
% Out:
%   elementVectorXY - vektor v rovině XY pro jednotlivé elementy     
%
% (c) S. Glanc, 2023

function [codes]=codeNumbersFn(beams,nodes)
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
    for i = 1:beams.nbeams
    codes(i,1:6) = dofs(beams.nodesHead(i),:);
    codes(i,7:12) = dofs(beams.nodesEnd(i),:);
    end
end
