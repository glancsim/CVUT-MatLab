function [displacements, endForces] = linearSolverFn(sections, nodes, ndisc, kinematic, beams, loads)
% linearSolverFn  Linear static analysis of a 2D beam frame structure.
%
% Performs a full linear FEM workflow for a 2D Euler-Bernoulli beam frame
% in the XZ plane.  Each node has 3 DOFs: ux (horizontal), uz (vertical),
% ry (rotation about the out-of-plane Y-axis).
%
% Each beam is discretised into 'ndisc' two-node elements (6 DOFs each).
% Hinges (moment releases) are supported via static condensation.
%
% INPUTS:
%   sections  - (struct) Cross-section properties (one row per section type).
%     .A      - [m²]  Cross-sectional area                    (nsec x 1)
%     .Iz     - [m⁴]  Second moment of area about local y     (nsec x 1)
%     .E      - [Pa]  Young's modulus                         (nsec x 1)
%
%   nodes     - (struct) Node geometry.
%     .x      - [m]   Global x-coordinates                   (nnodes x 1)
%     .z      - [m]   Global z-coordinates                   (nnodes x 1)
%
%   ndisc     - (int) Number of finite elements per beam (>= 1).
%
%   kinematic - (struct) Fixed DOFs (supports).
%     .x.nodes  - Node indices with fixed ux
%     .z.nodes  - Node indices with fixed uz
%     .ry.nodes - Node indices with fixed rotation ry
%
%   beams     - (struct) Beam topology.
%     .nodesHead  - (nbeams x 1) start node index
%     .nodesEnd   - (nbeams x 1) end node index
%     .sections   - (nbeams x 1) section index (1-based)
%     .releases   - (nbeams x 2) OPTIONAL logical matrix:
%                   col 1 = hinge at head node
%                   col 2 = hinge at end node
%
%   loads     - (struct) Applied nodal loads.
%     .x.nodes, .x.value   - [N]   Force in x           (n x 1)
%     .z.nodes, .z.value   - [N]   Force in z           (n x 1)
%     .ry.nodes, .ry.value - [N·m] Moment about y-axis  (n x 1)
%     Use empty arrays [] for directions with no load.
%
% OUTPUTS:
%   displacements - (struct)
%     .global - (ndofs x 1) free-DOF displacement vector [m or rad]
%               DOF order: node 1 (ux,uz,ry), node 2 (...), ...
%     .local  - (6 x nelement) local element displacements
%
%   endForces - (struct)
%     .global - (ndofs x 1) assembled load vector
%     .local  - (6 x nelement) internal forces in local coordinates:
%               row 1: N   at head  [N]      (+ = tension)
%               row 2: Vz  at head  [N]      (transverse shear)
%               row 3: My  at head  [N·m]    (bending moment)
%               row 4: N   at end   [N]
%               row 5: Vz  at end   [N]
%               row 6: My  at end   [N·m]
%
% EXAMPLE:
%   % Cantilever beam, length 5 m, tip vertical load -1000 N
%   sections.A = 1e-3; sections.Iz = 1e-5; sections.E = 210e9;
%   nodes.x = [0; 5]; nodes.z = [0; 0];
%   kinematic.x.nodes = [1]; kinematic.z.nodes = [1]; kinematic.ry.nodes = [1];
%   beams.nodesHead = [1]; beams.nodesEnd = [2]; beams.sections = [1];
%   loads.x.nodes = []; loads.x.value = [];
%   loads.z.nodes = [2]; loads.z.value = [-1000];
%   loads.ry.nodes = []; loads.ry.value = [];
%   [d, f] = linearSolverFn(sections, nodes, 1, kinematic, beams, loads);
%
% See also: stiffnessMatrixFn, EndForcesFn, plotFrameFn, plotInternalForcesFn
%
% (c) S. Glanc, 2026

%--------------------------------------------------------------------------
% BOUNDARY CONDITIONS
%--------------------------------------------------------------------------
nnodes       = numel(nodes.x);
nodes.dofs   = true(nnodes, 3);          % [ux, uz, ry]
nodes.dofs(kinematic.x.nodes,  1) = false;
nodes.dofs(kinematic.z.nodes,  2) = false;
nodes.dofs(kinematic.ry.nodes, 3) = false;

nodes.ndofs  = sum(nodes.dofs(:));
nodes.nnodes = nnodes;

%--------------------------------------------------------------------------
% BEAM SETUP
%--------------------------------------------------------------------------
nbeams            = numel(beams.nodesHead);
beams.nbeams      = nbeams;
beams.disc        = ones(nbeams, 1) * ndisc;
beams.vertex      = beamVertexFn(beams, nodes);
beams.codeNumbers = codeNumbersFn(beams, nodes);

%--------------------------------------------------------------------------
% ELEMENT SETUP — discretise, propagate sections and hinge releases
%--------------------------------------------------------------------------
elements          = discretizationBeamsFn(beams, nodes);
elements.sections = sectionToElementFn(sections, beams);
elements.ndofs    = max(elements.codeNumbers(:));

% Propagate releases to individual elements (only first/last element of each beam)
elements.releases = zeros(elements.nelement, 2);
if isfield(beams, 'releases')
    pos = 0;
    for p = 1:beams.nbeams
        c = beams.disc(p);
        elements.releases(pos + 1, 1) = beams.releases(p, 1);   % head element
        elements.releases(pos + c, 2) = beams.releases(p, 2);   % end element
        pos = pos + c;
    end
end

%--------------------------------------------------------------------------
% LOAD VECTOR
%--------------------------------------------------------------------------
forceVector = sparse( ...
    [loads.x.nodes*3-2; loads.z.nodes*3-1; loads.ry.nodes*3], ...
    1, ...
    [loads.x.value;     loads.z.value;     loads.ry.value], ...
    nnodes*3, 1);

% Extract free-DOF entries in code-number ordering
f = forceVector(reshape(nodes.dofs.', [], 1));

endForces.global = sparse(elements.ndofs, 1);
endForces.global(1:max(beams.codeNumbers(:))) = f;

%--------------------------------------------------------------------------
% LINEAR ANALYSIS
%--------------------------------------------------------------------------
transformationMatrix = transformationMatrixFn(elements);
stiffnesMatrix       = stiffnessMatrixFn(elements, transformationMatrix);

[endForces.local, displacements] = EndForcesFn( ...
    stiffnesMatrix, endForces, transformationMatrix, elements);
end
