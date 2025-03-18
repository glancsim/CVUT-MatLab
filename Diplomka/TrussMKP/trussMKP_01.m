clear;clc;addpath('../Resources/Truss');addpath('../Resources')
%------------------------------------------------------------------------
%   INPUTS
%------------------------------------------------------------------------
% Sections
r = [ 1 , 1 ];
[~,sizeR] = size(r);
sections.A  = pi() * r .^ 2;
sections.E  = 1000 * ones(1,sizeR);

%Nodes
nodes.x         = [0;3;0]
nodes.y         = [0;0;0]
nodes.z         = [0;0;3]

nodes.dofs      = [ 0 0 0;1 0 1;0 0 0];
                    
nodes.dofsNumb  = nodesDofsNumbFn(nodes) 
                

%Beams
beams.nodesHead = [1,3];
beams.nodesEnd  = [2,2];
beams.disc      = [1,1];
beams.sections.id  = [1,2];

%Load
loads.nodes.id  = [2];
loads.nodes.dir = [3];
loads.value  = [-1];
loads = loadInputFn(loads,nodes);

%------------------------------------------------------------------------
%   SOLVE
%------------------------------------------------------------------------
nodes.ndofs = sum(sum(nodes.dofs));
nodes.nnodes    = numel(nodes.x)

beams.nbeams  = numel(beams.nodesHead);
beams.ndofs  = nodes.ndofs;
beams.nelement  = beams.nbeams;
beams.vertex = beamVertexFn(beams,nodes);
beams.codeNumbers = codeNumbersFn(beams,nodes);
beams.XY = XYtoBeamsFn(beams);
beams.sections = sectionToBeamFn(sections,beams)

%------------------------------------------------------------------------
%   Linear analysis
%------------------------------------------------------------------------
endForces.global = loadToEndForcesFn(loads,beams);

transformationMatrix = transformationMatrixTrussFn(beams);

stiffnesMatrix = stiffnessMatrixTrussFn(beams,transformationMatrix);

[endForces.local,displacements] = EndForcesFn(stiffnesMatrix,endForces,transformationMatrix,beams);
% displacements.local
displacements.global
endForces.local




