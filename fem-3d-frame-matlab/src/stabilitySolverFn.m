function [Results] = stabilitySolverFn(sections, nodes, ndisc, kinematic, beams, loads, solver, relaxParam)
% stabilitySolverFn  Linear buckling (stability) analysis of a 3D beam frame.
%
% Performs a two-stage FEM analysis to determine critical load multipliers
% (buckling loads) and the corresponding buckling mode shapes for a 3D
% Euler-Bernoulli beam frame structure.
%
% Stage 1 — Linear static analysis: assembles the elastic stiffness matrix K
%   and computes internal element forces under the applied reference loads.
%
% Stage 2 — Stability analysis: assembles the geometric (stress-stiffening)
%   matrix Kg from the internal forces, then solves the generalized
%   eigenvalue problem:  K * phi = lambda * Kg * phi
%   The eigenvalues lambda are critical load multipliers: the structure
%   buckles when the applied load is scaled by lambda_min.
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
%               Higher values improve the accuracy of both displacements
%               and critical loads. Typical value: 10.
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
%   loads     - (struct) Applied reference nodal loads.
%               The critical load is lambda * loads, where lambda = Results.values.
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
%   solver    - "oofem"    (default) — geometric matrix from axial force only
%             - "mc-guire" — geometric matrix including moment contributions
%
%   relaxParam - (scalar, optional) Relaxation parameter for the stiffness
%               matrix regularization (Evgrafov 2005). Adds ε·I to the
%               global stiffness matrix where ε = relaxParam * max(diag(K)).
%               This makes K positive definite even when members with near-
%               zero cross-sections are present (topology optimization).
%               Default: 0 (no relaxation).  Typical value: 1e-7 to 1e-10.
%
% OUTPUTS:
%   Results   - (struct) Stability analysis results, sorted by ascending
%               critical load multiplier (smallest buckling load first).
%     .values  - Critical load multipliers (eigenvalues), sorted ascending.
%               The first buckling load = Results.values(1) * applied_load.
%               Negative values indicate that buckling occurs under reversed
%               loading.                                          (10 x 1)
%     .vectors - Corresponding buckling mode shapes (eigenvectors).
%               Each column is a mode shape normalized to unit length.
%               The ordering matches Results.values.              (ndofs x 10)
%
% EXAMPLE:
%   % Define a pinned-pinned column (length 4 m) under axial compression
%   sections.A  = 6.08e-4;  sections.Iy = 3.12e-8;
%   sections.Iz = 3.12e-8;  sections.Ix = 6.24e-8;
%   sections.E  = 210e9;    sections.v  = 0.3;
%
%   nodes.x = [0; 0];  nodes.y = [0; 0];  nodes.z = [0; 4];
%
%   kinematic.x.nodes = [1;2]; kinematic.y.nodes = [1;2];
%   kinematic.z.nodes = [1];   kinematic.rx.nodes = [1;2];
%   kinematic.ry.nodes = [1;2]; kinematic.rz.nodes = [1;2];
%
%   beams.nodesHead = [1]; beams.nodesEnd = [2];
%   beams.sections  = [1]; beams.angles   = [0];
%
%   loads.x.nodes = []; loads.x.value = [];
%   loads.y.nodes = []; loads.y.value = [];
%   loads.z.nodes = [2]; loads.z.value = [-1];  % 1 N reference compression
%   loads.rx.nodes = []; loads.rx.value = [];
%   loads.ry.nodes = []; loads.ry.value = [];
%   loads.rz.nodes = []; loads.rz.value = [];
%
%   Results = stabilitySolverFn(sections, nodes, 10, kinematic, beams, loads);
%   fprintf('First critical load: %.2f N\n', Results.values(1));
%   % For the Euler column: F_cr = pi^2 * E * I / L^2
%
% See also: linearSolverFn, stiffnessMatrixFn, EndForcesFn,
%           geometricMatrixFn, criticalLoadFn, sortValuesVectorFn
%
% (c) S. Glanc, 2023, updated 2025

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
nbeams            = numel(beams.nodesHead);
beams.nbeams      = nbeams;
beams.disc        = ones(nbeams, 1) * ndisc;
beams.vertex      = beamVertexFn(beams, nodes);
beams.codeNumbers = codeNumbersFn(beams, nodes);
beams.XY          = XYtoRotBeamsFn(beams, beams.angles);

%--------------------------------------------------------------------------
% ELEMENT SETUP — discretize beams, expand section properties
%--------------------------------------------------------------------------
elements          = discretizationBeamsFn(beams, nodes);

% Propagate hinge releases to individual elements
% (release applies only to the first / last element of each beam)
elements.releases = zeros(sum(beams.disc), 2);
if isfield(beams, 'releases')
    pos = 0;
    for p = 1:beams.nbeams
        c = beams.disc(p);
        elements.releases(pos+1, 1) = beams.releases(p, 1);  % head hinge
        elements.releases(pos+c, 2) = beams.releases(p, 2);  % tail hinge
        pos = pos + c;
    end
end

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
% OPTIONAL ARGUMENTS — defaults
%--------------------------------------------------------------------------
if nargin < 7, solver = "oofem"; end
if nargin < 8, relaxParam = 0;  end

%--------------------------------------------------------------------------
% STAGE 1: LINEAR ANALYSIS — solve K * u = f, compute internal forces
%--------------------------------------------------------------------------
transformationMatrix = transformationMatrixFn(elements);
stiffnesMatrix       = stiffnessMatrixFn(elements, transformationMatrix);

% Relaxation (Evgrafov 2005): K_reg = K + ε·I
% Regularizes K to be positive definite even with near-zero members.
if relaxParam > 0
    epsilon = relaxParam * max(abs(diag(stiffnesMatrix.global)));
    stiffnesMatrix.global = stiffnesMatrix.global + epsilon * speye(elements.ndofs);
end

endForces.local = EndForcesFn( ...
    stiffnesMatrix, endForces, transformationMatrix, elements);

%--------------------------------------------------------------------------
% STAGE 2: STABILITY ANALYSIS — geometric matrix and eigenvalue problem
%--------------------------------------------------------------------------

if solver == "mc-guire"
    geometricMatrix = geometricMatrixMcGuireFn(elements, transformationMatrix, endForces);
else
    geometricMatrix = geometricMatrixFn(elements, transformationMatrix, endForces);
end

Results = criticalLoadFn(stiffnesMatrix, geometricMatrix);
[Results.values, Results.vectors] = sortValuesVectorFn( ...
    Results.values, Results.vectors);

end
