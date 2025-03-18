
%
% In: 
% 
%
% Out:
%  
%
% (c) S. Glanc, 2022


function [forces]=loadToEndForcesFn(loads,elements)
    elements.ndofs = max(max(elements.codeNumbers));
    forces = zeros(elements.ndofs,1);
    for p=1:loads.nload   
        forces(loads.dir(p))=loads.value(p);
    end
end