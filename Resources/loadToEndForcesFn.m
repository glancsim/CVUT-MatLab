
%
% In: 
% 
%
% Out:
%  
%
% (c) S. Glanc, 2022


function [forces]=loadToEndForces(loads,elements)
    forces = zeros(elements.ndofs,1);
    for p=1:loads.nload   
        forces(loads.dir(p))=loads.value(p);
    end
end