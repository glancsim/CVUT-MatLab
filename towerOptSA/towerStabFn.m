function [value,volume] = towerStabFn(sectionsID)

% Sections

crossSectionsSet.import = importdata("../Bnb/Sections.mat");
crossSectionsSet.A = cat(1, table2array(crossSectionsSet.import.RHS(:,"A")), table2array(crossSectionsSet.import.L(:,"A")));
crossSectionsSet.Iy = cat(1, table2array(crossSectionsSet.import.RHS(:,"Iy")), table2array(crossSectionsSet.import.L(:,"Iu")));
crossSectionsSet.Iz = cat(1, table2array(crossSectionsSet.import.RHS(:,"Iz")), table2array(crossSectionsSet.import.L(:,"Iv")));
crossSectionsSet.Ip = cat(1, table2array(crossSectionsSet.import.RHS(:,"Ip")), table2array(crossSectionsSet.import.L(:,"Ip")));

% disp(['g1=',num2str(sectionsID(1))])
% disp(['g2=',num2str(sectionsID(2))])
% disp(['g3=',num2str(sectionsID(3))])
sections.id = sectionsID;

sections.A  = [crossSectionsSet.A(sections.id(1));crossSectionsSet.A(sections.id(2));crossSectionsSet.A(sections.id(3))];
sections.Iy = [crossSectionsSet.Iy(sections.id(1));crossSectionsSet.Iy(sections.id(2));crossSectionsSet.Iy(sections.id(3))];
sections.Iz = [crossSectionsSet.Iz(sections.id(1));crossSectionsSet.Iz(sections.id(2));crossSectionsSet.Iz(sections.id(3))];
sections.Ix = [crossSectionsSet.Ip(sections.id(1));crossSectionsSet.Ip(sections.id(2));crossSectionsSet.Ip(sections.id(3))];
sections.E  = ones(3,1) * 210*10^9;
sections.v  = ones(3,1) * 0.3;

% Nodes

width = 2.9;
length = 2.9;
height = 3;
nbricks = 7;
nodes.x = kron(ones(nbricks+1,1),[0;length;length;0]);                            % x coordinates of nodes
nodes.y = kron(ones(nbricks+1,1),[0;0;width;width]);                              % y coordinates of nodes
nodes.z = kron([height;height;height;height], ones(nbricks+1, 1)) ...
        .* repelem((0:nbricks)', numel([height;height;height;height]), 1)  ;
nodes.z((nbricks)*4+1:(nbricks+1)*4) =[20;20;20;20]; % z coordinates of nodes
nnodes = numel(nodes.x); 

% Supports

kinematic.x.nodes = [1;2;3;4];              % node indices with restricted x-direction displacements
kinematic.y.nodes = [1;2;3;4];              % node indices with restricted y-direction displacements
kinematic.z.nodes = [1;2;3;4];              % node indices with restricted z-direction displacements
kinematic.rx.nodes = [];                    % node indices with restricted x-direction displacements
kinematic.ry.nodes = [];                   % node indices with restricted y-direction displacements
kinematic.rz.nodes = [];                    % node indices with restricted z-direction displacements

nodes.dofs = true(nnodes,6);                % no kinematic boundary conditions
nodes.dofs(kinematic.x.nodes,1) = false;    % mark prevented movement in x-direction
nodes.dofs(kinematic.y.nodes,2) = false;    % mark prevented movement in y-direction
nodes.dofs(kinematic.z.nodes,3) = false;    % mark prevented movement in z-direction
nodes.dofs(kinematic.rx.nodes,4) = false;    % mark prevented movement in x-direction
nodes.dofs(kinematic.ry.nodes,5) = false;    % mark prevented movement in y-direction
nodes.dofs(kinematic.rz.nodes,6) = false;    % mark prevented movement in z-direction
% Beams

modulNodes1 = [1;2;3;4; 1;2;2;3;3;4;4;1; 5;6;7;8  ];   % elements starting nodes
beams.nodesHead = (reshape(kron(modulNodes1', ones(nbricks, 1))', 1, [])' ...
        + repelem((0:nbricks-1)', numel(modulNodes1))*4);
modulNodes2 = [5;6;7;8; 6;5;7;6;8;7;5;8; 6;7;8;5  ];   % elements ending nodes
beams.nodesEnd = (reshape(kron(modulNodes2', ones(nbricks, 1))', 1, [])' ...
        + repelem((0:nbricks-1)', numel(modulNodes2))*4);
nr = numel(beams.nodesHead);
% Beams sections

beams.disc      = ones(nr,1)*4;
modulElemGroup = [1;1;1;1; 2;2;2;2;2;2;2;2;    3;3;3;3];
beams.sections = reshape(kron(modulElemGroup', ones(nbricks, 1))', 1, [])';
ng = max(max(beams.sections));
% plot3([nodes.x(beams.nodesHead) nodes.x(beams.nodesEnd)]', ...
%      [nodes.y(beams.nodesHead) nodes.y(beams.nodesEnd)]', ...
%      [nodes.z(beams.nodesHead) nodes.z(beams.nodesEnd)]', ...
%      'k','LineWidth',1);
% hold on;
% scatter3(nodes.x, nodes.y, nodes.z, 'blue', 'filled', 'o');
% axis equal;
% xlim([min(nodes.x)-1,max(nodes.x)+1]);  % to avoid tight limits
% ylim([min(nodes.y)-1,max(nodes.y)+1]);  % to avoid tight limits
% zlim([min(nodes.z)-1,max(nodes.z)+1]);  % to avoid tight limits
% grid on
% view([90 0])
% hold off;
% Loads

loads.x.nodes = [1;2;3;4]+(nbricks)*4;             % node indices with x-direction forces
loads.x.value = [-10000;-10000;-10000;-10000];             % magnitude of the x-direction forces
loads.y.nodes = reshape((repmat([1,2], nbricks, 1) + (1:nbricks)'*4).',1,[])';          % node indices with y-direction forces
loads.y.value = ones(nbricks*2,1)*0.25;          % magnitude of the y-direction forces 
loads.z.nodes = [1;2;3;4]+(nbricks)*4;             % node indices with z-direction forces
loads.z.value = [-10000;-10000;-10000;-10000];

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



%------------------------------------------------------------------------
%   Linear analysis
%------------------------------------------------------------------------
endForces.global = sparse(elements.ndofs,1);
endForces.global(1:max(max(beams.codeNumbers))) = f;

transformationMatrix = transformationMatrixFn(elements);

stiffnesMatrix = stiffnessMatrixFn(elements,transformationMatrix);

endForces.local = EndForcesFn(stiffnesMatrix,endForces,transformationMatrix,elements);
%------------------------------------------------------------------------
%   Non-linear analysis
%------------------------------------------------------------------------
geometricMatrix = geometricMatrixFn(elements,transformationMatrix,endForces);

SortedResults = criticalLoadFnV2(stiffnesMatrix,geometricMatrix);

volume = sum(elements.sections.A .* transformationMatrix.lengths);
cond = SortedResults > 0; 
positiveValues = SortedResults(cond);
value = positiveValues(1);
end
