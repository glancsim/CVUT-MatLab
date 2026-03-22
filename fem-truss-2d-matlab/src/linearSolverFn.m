function [displacements, endForces] = linearSolverFn(sections, nodes, kinematic, members, loads)
% linearSolverFn  Linear static analysis of a 2D pin-jointed truss.
%
% Each member carries axial force only (no bending, no torsion).
% Nodes have 2 DOFs: ux (horizontal) and uz (vertical).
%
% INPUTS:
%   sections  - (struct) Cross-section properties.
%     .A      - [m^2]  Cross-sectional area          (nsec x 1)
%     .E      - [Pa]   Young's modulus               (nsec x 1)
%
%   nodes     - (struct) Node geometry.
%     .x      - [m]    Global x-coordinates          (nnodes x 1)
%     .z      - [m]    Global z-coordinates          (nnodes x 1)
%
%   kinematic - (struct) Kinematic boundary conditions (fixed DOFs).
%     .x.nodes  - Node indices with fixed x-translation
%     .z.nodes  - Node indices with fixed z-translation
%
%   members   - (struct) Truss member topology.
%     .nodesHead - Start node index for each member   (nmembers x 1)
%     .nodesEnd  - End node index for each member     (nmembers x 1)
%     .sections  - Section index (1-based)            (nmembers x 1)
%
%   loads     - (struct) Applied nodal loads.
%     .x.nodes, .x.value  - [N]  Force in global x   (n x 1 each)
%     .z.nodes, .z.value  - [N]  Force in global z   (n x 1 each)
%     Use empty arrays [] for directions with no load.
%
% OUTPUTS:
%   displacements - (struct)
%     .global     - Free-DOF displacement vector [m]  (ndofs x 1)
%                   DOF ordering: node 1 (ux, uz), node 2 (ux, uz), ...
%     .local      - Element displacements in local (axial) coords (2 x nmembers)
%                   Row 1 = axial displacement at head node [m]
%                   Row 2 = axial displacement at end  node [m]
%
%   endForces     - (struct)
%     .global     - Assembled load vector              (ndofs x 1)
%     .local      - Element forces in local coords     (4 x nmembers)
%                   Row 1 = N at head node [N] (positive = tension)
%                   Row 2 = transverse force at head (always 0 for truss)
%                   Row 3 = N at end  node [N] (= -row1 for equilibrium)
%                   Row 4 = transverse force at end  (always 0 for truss)
%
% EXAMPLE:
%   % Simple symmetric 3-bar truss: apex at (2,0,2), supports at (0,0,0) and (4,0,0)
%   sections.A = 1e-4;  sections.E = 210e9;
%   nodes.x = [0;4;2];  nodes.z = [0;0;2];
%   kinematic.x.nodes = [1;2];  kinematic.z.nodes = [1;2];
%   members.nodesHead = [1;2;1];  members.nodesEnd = [3;3;2];
%   members.sections = [1;1;1];
%   loads.x.nodes = []; loads.x.value = [];
%   loads.z.nodes = [3]; loads.z.value = [-1000];
%   [d, f] = linearSolverFn(sections, nodes, kinematic, members, loads);
%
% See also: memberVertexFn, codeNumbersFn, transformationMatrixFn,
%           stiffnessMatrixFn, EndForcesFn, plotTrussFn
%
% (c) S. Glanc, 2025

%--------------------------------------------------------------------------
% BOUNDARY CONDITIONS — build nodes.dofs from kinematic constraints
%--------------------------------------------------------------------------
nnodes       = numel(nodes.x);
nodes.dofs   = true(nnodes, 2);          % col 1 = ux, col 2 = uz
nodes.dofs(kinematic.x.nodes, 1) = false;
nodes.dofs(kinematic.z.nodes,  2) = false;

nodes.ndofs  = sum(sum(nodes.dofs));
nodes.nnodes = nnodes;

%--------------------------------------------------------------------------
% MEMBER SETUP — direction vectors, code numbers
%--------------------------------------------------------------------------
nmembers            = numel(members.nodesHead);
members.nmembers    = nmembers;
members.vertex      = memberVertexFn(members, nodes);
members.codeNumbers = codeNumbersFn(members, nodes);

%--------------------------------------------------------------------------
% ELEMENT SETUP — 1:1 with members (no discretization for trusses)
%--------------------------------------------------------------------------
elements          = members;
elements.nelement = nmembers;
secIdx            = members.sections;          % (nmembers×1) section index
elements.sections = struct();                  % replace index array with properties
elements.sections.A = sections.A(secIdx);
elements.sections.E = sections.E(secIdx);
elements.ndofs       = max(max(elements.codeNumbers));

%--------------------------------------------------------------------------
% LOAD VECTOR — assemble global force vector from nodal loads
%--------------------------------------------------------------------------
forceVector = sparse( ...
    [loads.x.nodes*2-1; loads.z.nodes*2], ...
    1, ...
    [loads.x.value; loads.z.value], ...
    nnodes*2, 1);

% Extract entries for free DOFs only (matching code-number ordering)
f = forceVector(reshape(reshape(nodes.dofs.', [], 1).', 1, [])');

endForces.global = sparse(elements.ndofs, 1);
endForces.global(1:max(max(members.codeNumbers))) = f;

%--------------------------------------------------------------------------
% LINEAR ANALYSIS — assemble K, solve, compute element forces
%--------------------------------------------------------------------------
transformationMatrix = transformationMatrixFn(elements);
stiffnesMatrix       = stiffnessMatrixFn(elements, transformationMatrix);

[endForces, displacements] = EndForcesFn( ...
    stiffnesMatrix, endForces, transformationMatrix, elements);

end
