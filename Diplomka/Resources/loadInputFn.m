
%
% In: 
% 
%
% Out:
%  
%
% (c) S. Glanc, 2022


function [loads]=loadInputFn(loads,nodes)
    dofs = nodes.dofsNumb;
    for i = 1 : size(loads.nodes.id,2)
        loads.dir(i)    = dofs(loads.nodes.id(i),loads.nodes.dir(i));
    end
    loads.nload  = size(loads.nodes.id,2);
end