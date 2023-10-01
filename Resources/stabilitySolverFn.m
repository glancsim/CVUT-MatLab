% Výpočet stability konstrukcí
%
% In: 
%   sections    =  průřezy ve formátu viz Example1.m     
%   nodes       =  styčníky ve formátu viz Example1.m  
%   beams       =  nosníky ve formátu viz Example1.m  
%   loads       =  zatížení ve formátu viz Example1.m      
% Out:
%   Results     = výsledky obsahující vlastní čísla a vektory
% 
% (c) S. Glanc, 2023

function [Results] = stabilitySolverFn(sections, nodes, beams,loads)
%------------------------------------------------------------------------
%   SOLVE
%------------------------------------------------------------------------
nodes.ndofs = sum(sum(nodes.dofs));
nodes.nnodes    = numel(nodes.x)

beams.nbeams  = numel(beams.nodesHead);
beams.vertex = beamVertexFn(beams,nodes);
beams.codeNumbers = codeNumbersFn(beams,nodes);
beams.XY = XYtoBeamsFn(beams);

elements = discretizationBeamsFn(beams,nodes);
elements.XY = XYtoElementFn(beams);
elements.sections = sectionToElementFn(sections,beams);
elements.ndofs = max(max(elements.codeNumbers))

loads.nload  = size(loads,2);
%------------------------------------------------------------------------
%   Linear analysis
%------------------------------------------------------------------------
endForces.global = loadToEndForcesFn(loads,elements);

transformationMatrix = transformationMatrixFn(elements);

stiffnesMatrix = stiffnessMatrixFn(elements,transformationMatrix);

endForces.local = EndForcesFn(stiffnesMatrix,endForces,transformationMatrix,elements);
%------------------------------------------------------------------------
%   Non-linear analysis
%------------------------------------------------------------------------
geometricMatrix = geometricMatrixFn(elements,transformationMatrix,endForces);

%------------------------------------------------------------------------
%   Results
%------------------------------------------------------------------------
Results = criticalLoadFn(stiffnesMatrix,geometricMatrix);
end


