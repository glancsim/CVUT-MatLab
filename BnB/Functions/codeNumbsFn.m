function [codeNum]=codeNumbsFn(startNodes, endNodes, nelem, dofs)
   [s,k] = size(dofs);
    dofsId = zeros(s,k);
    m = 0;
    for g = 1:s
        for j = 1:k
            if dofs(g,j) == 1
                dofsId(g,j) = dofs(g,j) + m;
                m = m+1;
            end
        end
    end
    k1 = k  ;
    k2 = k + 1 ; 
    k3 = 2*k ;
%     beams.nbeams
    codeNum = zeros(nelem,k3);
    for i = 1:nelem
    codeNum(i,1:k1) = dofsId(startNodes(i),:);
    codeNum(i,k2:k3) = dofsId(endNodes(i),:);
    end
end