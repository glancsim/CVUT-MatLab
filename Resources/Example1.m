clear
clc
addpath('../Resources')
%------------------------------------------------------------------------
%   INPUTS
%------------------------------------------------------------------------
% Sections in mm
sections.A  = mmTomFn(1.27*10^4,2);
sections.Iy = mmTomFn(3.66*10^7,4);
sections.Iz = sections.Iy;
sections.Ix = sections.Iy * 2;
sections.E  = 200*10^9;
sections.v  = 0.3;

%Nodes
nodes.x         = [0;0]
nodes.y         = [0;8]
nodes.z         = [0;0]

nodes.dofs      = [ 0 0 0 1 0 1;...
                    0 1 0 1 1 1];
                

%Beams
beams.nodesHead = [1];
beams.nodesEnd  = [2];
beams.disc      = [4];
beams.sections  = [1];

%Load
loads.dir    = 3;
loads.value  = -1;


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

Results = criticalLoadFn(stiffnesMatrix,geometricMatrix);

SortedResults = sortValuesVectorFn(Results.values,Results.vectors);

disp('První kritické břemeno')
disp([num2str(SortedResults(1)),' N'])
disp('Druhé kritické břemeno')
disp([num2str(SortedResults(2)),' N'])
disp('Třetí kritické břemeno')
disp([num2str(SortedResults(3)),' N'])

