function stress = Truss01Fn(r,idx)
addpath('../Resources')
%------------------------------------------------------------------------
%   INPUTS
%------------------------------------------------------------------------
% Sections
r = [ 1 , 1 ];
[~,sizeR] = size(r)
sections.A  = pi() * r .^ 2;
sections.Iy = 1/4 * pi() * r .^ 4;
sections.Iz = sections.Iy;
sections.Ix = sections.Iy * 2;
sections.E  = 1000 * ones(1,sizeR);
sections.v  = 0.3 * ones(1,sizeR);

%Nodes
nodes.x         = [0;0;0]
nodes.y         = [0;8;16]
nodes.z         = [0;0;0]

nodes.dofs      = [ 0 0 0 0 0 0;...
                    1 1 1 1 1 1;...
                    1 1 1 1 1 1];
                    
nodes.dofsNumb  = nodesDofsNumbFn(nodes) 
                

%Beams
beams.nodesHead = [1,2];
beams.nodesEnd  = [2,3];
beams.disc      = [1,1];
beams.sections  = [1,2];

%Load
loads.nodes.id  = [3,3];
loads.nodes.dir = [1,2];
loads.value  = [-1,-3];
loads = loadInputFn(loads,nodes);

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
elements.ndofs = max(max(elements.codeNumbers));


%------------------------------------------------------------------------
%   Linear analysis
%------------------------------------------------------------------------
endForces.global = loadToEndForcesFn(loads,elements);

transformationMatrix = transformationMatrixFn(elements);

stiffnesMatrix = stiffnessMatrixFn(elements,transformationMatrix);

[endForces.local,displacements] = EndForcesFn(stiffnesMatrix,endForces,transformationMatrix,elements);
% displacements.local
% displacements.global
% endForces.local
for i = 1 : size(endForces.local,2)
    normalStress(i) = endForces.local(7,i) / sections.A(i);
end
stress = normalStress(idx);
end




