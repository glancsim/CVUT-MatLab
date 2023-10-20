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
    dofs = zeros(s,k);
    m = 0;
    for g = 1:s
        for j = 1:k
            if nodes.dofs(g,j) == 1
                dofs(g,j) = nodes.dofs(g,j) + m;
                m = m+1;
            end
        end
    end
    s1 = s  ;
    s2 = s + 1 ; 
    s3 = 2*s ;
%     beams.nbeams
    codes = zeros(beams.nbeams,s3);
    for i = 1:beams.nbeams
    codes(i,1:s1) = dofs(beams.nodesHead(i),:);
    codes(i,s2:s3) = dofs(beams.nodesEnd(i),:);
    end
end
