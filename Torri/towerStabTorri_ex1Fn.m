function [value, volume] = towerStabTorri_ex1Fn(outRadius)

outRadius = outRadius*10^-3;
inRadius = outRadius*0.9;

for j = 1:size(outRadius,1)
    sections.A(j,1) = outRadius(j)^2*pi() - inRadius(j)^2*pi() ;
    sections.Iy(j,1) = pi() * outRadius(j) ^ 4 / 4 - pi() * inRadius(j) ^ 4 / 4  ;
end


sections.Iz = sections.Iy;
sections.Ix = sections.Iy*2;
sections.E  = ones(size(outRadius,1),1) * 210*10^9;
sections.v  = ones(size(outRadius,1),1) * 0.3;

ndisc = 8;

% Nodes

nodes.x = [0;4;8;0;4];                          % x coordinates of nodes
nodes.y = [0;0;0;0;0];                          % y coordinates of nodes
nodes.z = [0;0;0;4;4];                          % z coordinates of nodes
nnodes = numel(nodes.x); 
% Supports

kinematic.x.nodes = [1;4];              % node indices with restricted x-direction displacements
kinematic.y.nodes = [1;4];              % node indices with restricted y-direction displacements
kinematic.z.nodes = [1;4];              % node indices with restricted z-direction displacements
kinematic.rx.nodes = [];                    % node indices with restricted x-direction displacements
kinematic.ry.nodes = [];                   % node indices with restricted y-direction displacements
kinematic.rz.nodes = [1;4];                    % node indices with restricted z-direction displacements

nodes.dofs = true(nnodes,6);                % no kinematic boundary conditions
nodes.dofs(kinematic.x.nodes,1) = false;    % mark prevented movement in x-direction
nodes.dofs(kinematic.y.nodes,2) = false;    % mark prevented movement in y-direction
nodes.dofs(kinematic.z.nodes,3) = false;    % mark prevented movement in z-direction
nodes.dofs(kinematic.rx.nodes,4) = false;    % mark prevented movement in x-direction
nodes.dofs(kinematic.ry.nodes,5) = false;    % mark prevented movement in y-direction
nodes.dofs(kinematic.rz.nodes,6) = false;    % mark prevented movement in z-direction
% Beams

beams.nodesHead = [1;1;4;4;2;2;5];   % elements starting nodes
beams.nodesEnd  = [2;5;2;5;5;3;3];   % elements ending nodes
nr = numel(beams.nodesHead);
% Beams sections

beams.disc      = ones(nr,1)*ndisc;
beams.sections  = 1:size(outRadius,1);

ng = max(max(beams.sections));

% Loads

loads.y.nodes = [];           % node indices with x-direction forces
loads.y.value = [];           % magnitude of the x-direction forces
loads.x.nodes = [];           % node indices with y-direction forces
loads.x.value = [];           % magnitude of the y-direction forces 
loads.z.nodes = [3];           % node indices with y-direction forces
loads.z.value = [-150*10^3];           % magnitude of the y-direction forces 

loads.rx.nodes = [];          % node indices with x-direction forces
loads.rx.value = [];          % magnitude of the x-direction forces
loads.ry.nodes = [];          % node indices with y-direction forces
loads.ry.value = [];          % magnitude of the y-direction forces 
loads.rz.nodes = [];          % node indices with z-direction forces
loads.rz.value = []; 

% Force vector

forceVector = sparse([loads.x.nodes*6-5; loads.y.nodes*6-4; loads.z.nodes*6-3;loads.rx.nodes*3-2; loads.ry.nodes*3-1; loads.rz.nodes*3], ...
                     1, ...
                     [loads.x.value; loads.y.value; loads.z.value;loads.rx.value; loads.ry.value; loads.rz.value], ...
                     nnodes*6, 1);
f = forceVector(reshape(reshape(nodes.dofs.',[],1).', 1, [])');
% FEM

nodes.ndofs = sum(sum(nodes.dofs));
nodes.nnodes    = nnodes;

beams.nbeams  = nr;
beams.vertex = beamVertexFn(beams,nodes);
beams.codeNumbers = codeNumbersFn(beams,nodes);
beams.XY = XYtoBeamsFn(beams);

elements = discretizationBeamsFn(beams,nodes);
elements.XY = XYtoElementFn(beams);
elements.sections = sectionToElementFn(sections,beams);
elements.ndofs = max(max(elements.codeNumbers));


% Linear analysis 
% Frames

endForces.global = sparse(elements.ndofs,1);
endForces.global(1:max(max(beams.codeNumbers))) = f;

transformationMatrix = transformationMatrixFn(elements);

stiffnesMatrix = stiffnessMatrixFn(elements,transformationMatrix);

[endForces.local, displ] = endForcesFn(stiffnesMatrix,endForces,transformationMatrix,elements);
% Non-linear analysis

geometricMatrix = geometricMatrixFnV2(elements,transformationMatrix,endForces);

volume = sum(elements.sections.A .* transformationMatrix.lengths);
Results = criticalLoadFn(stiffnesMatrix,geometricMatrix,10);

[sortedValues,sortedVectors]= sortValuesVectorFn(Results.values,Results.vectors);

cond = sortedValues > 0; 
positiveValues = sortedValues(cond);
value = min(positiveValues);
% stress = zeros(nr,1);
% for i = 1:nr
%     idR = 1:12;
%     idC = (i-1)*ndisc + 1 : i*ndisc;
%     endForces.beams{i} = endForces.local(idR, idC);
%     N(i)=endForces.beams{i}(7,1);
%     if N(i) < 0
%         euler = beams.E(i) * beams.I(i) * pi^2 / (beams.lengths(i)^2*beams.A(i)) ;
%         stress(i) = N(i) / beams.A(i)/(-min(yieldingStress,euler));
%     else
%         stress(i) = N(i) / beams.A(i)/yieldingStress ;
%     end
% end
% stressCond = sum(stress>1);
    if isempty(value)
        Results = criticalLoadFn(stiffnesMatrix,geometricMatrix,elements.ndofs);

        [sortedValues,sortedVectors]= sortValuesVectorFn(Results.values,Results.vectors);

        cond = sortedValues > 0; 
        positiveValues = sortedValues(cond);
        value = min(positiveValues);
    end
end