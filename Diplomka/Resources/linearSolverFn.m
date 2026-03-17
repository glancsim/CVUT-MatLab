function [displacements, endForces] = linearSolverFn(sections, nodes, ndisc, kinematic, beams, loads)
% linearSolverFn  Linear static analysis of a 3D beam frame structure.
%
% Performs a full linear FEM workflow for a 3D Euler-Bernoulli beam
% structure: assembles the global stiffness matrix, applies boundary
% conditions and nodal loads, solves for displacements, and computes
% internal element forces in local coordinates.
%
% Each beam is discretized into 'ndisc' two-node Hermite beam elements
% with 6 DOFs per node (ux, uy, uz, rx, ry, rz), giving 12 DOFs per
% element. All quantities use SI units throughout.
%
% INPUTS:
%   sections  - (struct) Cross-section properties, one entry per section type.
%     .A      - [m^2] Cross-sectional area                         (nsec x 1)
%     .Iy     - [m^4] Second moment of area about local y-axis     (nsec x 1)
%     .Iz     - [m^4] Second moment of area about local z-axis     (nsec x 1)
%     .Ix     - [m^4] Torsional (polar) moment of inertia          (nsec x 1)
%     .E      - [Pa]  Young's modulus                              (nsec x 1)
%     .v      - [-]   Poisson's ratio                              (nsec x 1)
%
%   nodes     - (struct) Node geometry.
%     .x      - [m]   Global x-coordinates                        (nnodes x 1)
%     .y      - [m]   Global y-coordinates                        (nnodes x 1)
%     .z      - [m]   Global z-coordinates                        (nnodes x 1)
%
%   ndisc     - (int) Number of finite elements per beam (must be >= 1).
%               Higher values increase accuracy for distributed loads
%               and stability analyses. Typical value: 10.
%
%   kinematic - (struct) Kinematic boundary conditions (supports).
%               Each field contains a column vector of node indices (1-based)
%               where the corresponding DOF is fully fixed (prescribed zero).
%     .x.nodes  - Nodes with fixed x-translation
%     .y.nodes  - Nodes with fixed y-translation
%     .z.nodes  - Nodes with fixed z-translation
%     .rx.nodes - Nodes with fixed rotation about x-axis
%     .ry.nodes - Nodes with fixed rotation about y-axis
%     .rz.nodes - Nodes with fixed rotation about z-axis
%
%   beams     - (struct) Beam topology and cross-section assignment.
%     .nodesHead - Start node index for each beam                  (nbeams x 1)
%     .nodesEnd  - End node index for each beam                    (nbeams x 1)
%     .sections  - Section index (1-based into sections struct)    (nbeams x 1)
%     .angles    - [deg] Rotation of cross-section about beam axis (nbeams x 1)
%               A value of 0 aligns the local z-axis with the global Z-axis
%               (or Y-axis for vertical beams). Positive rotation follows
%               the right-hand rule about the beam's local x-axis.
%
%   loads     - (struct) Applied nodal loads (forces and moments).
%               Each direction has two parallel arrays: node indices and values.
%     .x.nodes  - Node indices with force in global x-direction    (n x 1)
%     .x.value  - [N]   Force magnitudes (positive = +x direction) (n x 1)
%     .y.nodes  - Node indices with force in global y-direction    (n x 1)
%     .y.value  - [N]   Force magnitudes                          (n x 1)
%     .z.nodes  - Node indices with force in global z-direction    (n x 1)
%     .z.value  - [N]   Force magnitudes                          (n x 1)
%     .rx.nodes - Node indices with moment about global x-axis     (n x 1)
%     .rx.value - [N*m] Moment magnitudes                         (n x 1)
%     .ry.nodes - Node indices with moment about global y-axis     (n x 1)
%     .ry.value - [N*m] Moment magnitudes                         (n x 1)
%     .rz.nodes - Node indices with moment about global z-axis     (n x 1)
%     .rz.value - [N*m] Moment magnitudes                         (n x 1)
%               Use empty arrays [] for directions with no load.
%
% OUTPUTS:
%   displacements - (struct) Nodal displacements.
%     .global - Free-DOF displacement vector [m or rad]  (ndofs x 1)
%               DOF ordering: node 1 (ux,uy,uz,rx,ry,rz), node 2 (...), ...
%               Only free (unconstrained) DOFs are included.
%     .local  - Element displacements in local coordinates        (12 x nelement)
%               Rows 1-6: start-node DOFs; rows 7-12: end-node DOFs.
%               Order per node: [ux, uy, uz, rx, ry, rz]
%
%   endForces     - (struct) Internal element forces and moments.
%     .global - Global nodal force vector [N or N*m]              (ndofs x 1)
%               The assembled right-hand-side vector (applied loads).
%     .local  - Element end-forces in local coordinates [N, N*m]  (12 x nelement)
%               Row index per element (local coordinates):
%                  1: N   (axial force at start node)
%                  2: Vy  (shear force y at start node)
%                  3: Vz  (shear force z at start node)
%                  4: Mx  (torsional moment at start node)
%                  5: My  (bending moment y at start node)
%                  6: Mz  (bending moment z at start node)
%                  7-12:  same quantities at end node
%
% EXAMPLE:
%   % Define a simple cantilever beam along the x-axis (length 5 m)
%   sections.A  = 6.08e-4;  sections.Iy = 3.12e-8;
%   sections.Iz = 3.12e-8;  sections.Ix = 6.24e-8;
%   sections.E  = 210e9;    sections.v  = 0.3;
%
%   nodes.x = [0; 5];  nodes.y = [0; 0];  nodes.z = [0; 0];
%
%   kinematic.x.nodes = [1]; kinematic.y.nodes = [1];
%   kinematic.z.nodes = [1]; kinematic.rx.nodes = [1];
%   kinematic.ry.nodes = [1]; kinematic.rz.nodes = [1];
%
%   beams.nodesHead = [1]; beams.nodesEnd = [2];
%   beams.sections  = [1]; beams.angles   = [0];
%
%   loads.x.nodes = []; loads.x.value = [];
%   loads.y.nodes = [2]; loads.y.value = [-1000];
%   loads.z.nodes = []; loads.z.value = [];
%   loads.rx.nodes = []; loads.rx.value = [];
%   loads.ry.nodes = []; loads.ry.value = [];
%   loads.rz.nodes = []; loads.rz.value = [];
%
%   [displ, forces] = linearSolverFn(sections, nodes, 10, kinematic, beams, loads);
%   % displ.global contains the free-DOF displacement vector
%
% See also: stabilitySolverFn, stiffnessMatrixFn, EndForcesFn,
%           transformationMatrixFn, geometricMatrixFn, criticalLoadFn
%
% (c) S. Glanc, 2025

%--------------------------------------------------------------------------
% BOUNDARY CONDITIONS — build nodes.dofs from kinematic constraints
%--------------------------------------------------------------------------
nnodes       = numel(nodes.x);
nodes.dofs   = true(nnodes, 6);
nodes.dofs(kinematic.x.nodes,  1) = false;
nodes.dofs(kinematic.y.nodes,  2) = false;
nodes.dofs(kinematic.z.nodes,  3) = false;
nodes.dofs(kinematic.rx.nodes, 4) = false;
nodes.dofs(kinematic.ry.nodes, 5) = false;
nodes.dofs(kinematic.rz.nodes, 6) = false;

nodes.ndofs  = sum(sum(nodes.dofs));
nodes.nnodes = nnodes;

%--------------------------------------------------------------------------
% BEAM SETUP — direction vectors, code numbers, reference plane
%--------------------------------------------------------------------------
nbeams           = numel(beams.nodesHead);
beams.nbeams     = nbeams;
beams.disc       = ones(nbeams, 1) * ndisc;
beams.vertex     = beamVertexFn(beams, nodes);
beams.codeNumbers = codeNumbersFn(beams, nodes);
beams.XY         = XYtoRotBeamsFn(beams, beams.angles);

%--------------------------------------------------------------------------
% ELEMENT SETUP — discretize beams, expand section properties
%--------------------------------------------------------------------------
elements          = discretizationBeamsFn(beams, nodes);
elements.XY       = XYtoElementFn(beams);
elements.sections = sectionToElementFn(sections, beams);
elements.ndofs    = max(max(elements.codeNumbers));

%--------------------------------------------------------------------------
% LOAD VECTOR — assemble global force vector from nodal loads
%--------------------------------------------------------------------------
forceVector = sparse( ...
    [loads.x.nodes*6-5; loads.y.nodes*6-4; loads.z.nodes*6-3; ...
     loads.rx.nodes*6-2; loads.ry.nodes*6-1; loads.rz.nodes*6], ...
    1, ...
    [loads.x.value; loads.y.value; loads.z.value; ...
     loads.rx.value; loads.ry.value; loads.rz.value], ...
    nnodes*6, 1);

% Extract entries for free DOFs only (matching code-number ordering)
f = forceVector(reshape(reshape(nodes.dofs.', [], 1).', 1, [])');

endForces.global = sparse(elements.ndofs, 1);
endForces.global(1:max(max(beams.codeNumbers))) = f;

%--------------------------------------------------------------------------
% LINEAR ANALYSIS — stiffness matrix, solve K*u = f
%--------------------------------------------------------------------------
transformationMatrix = transformationMatrixFn(elements);
stiffnesMatrix       = stiffnessMatrixFn(elements, transformationMatrix);

[endForces.local, displacements] = EndForcesFn( ...
    stiffnesMatrix, endForces, transformationMatrix, elements);

end
