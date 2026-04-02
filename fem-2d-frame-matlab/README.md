# fem-2d-frame-matlab

Linear static analysis of **2D beam frame structures** (Euler-Bernoulli) in the XZ plane.

Each node has **3 DOFs**: `ux` (horizontal), `uz` (vertical), `ry` (rotation about Y-axis).  
Moment releases (hinges) are supported on any beam end via static condensation.

## Module structure

```
fem-2d-frame-matlab/
  src/
    linearSolverFn.m        ← main entry point
    beamVertexFn.m
    codeNumbersFn.m
    discretizationBeamsFn.m
    sectionToElementFn.m
    transformationMatrixFn.m
    stiffnessMatrixFn.m     ← includes releaseCondenseFn
    EndForcesFn.m
    plotFrameFn.m
  tests/
    generate_references.m
    run_all_tests.m
    run_single_test.m
    Test 1/  — cantilever beam (analytical)
    Test 2/  — fixed-fixed beam (analytical)
    Test 3/  — portal frame with hinge (FEM reference)
  examples/
    example_cantilever.m
    example_portal_frame.m
```

## Quick start

```matlab
% Add source to path
addpath('fem-2d-frame-matlab/src');

% Define section
sections.A  = 1e-3;   % [m²]
sections.Iz = 1e-5;   % [m⁴]
sections.E  = 210e9;  % [Pa]

% Nodes (XZ plane)
nodes.x = [0; 5];
nodes.z = [0; 0];

% Supports — fully fixed at node 1
kinematic.x.nodes  = [1];
kinematic.z.nodes  = [1];
kinematic.ry.nodes = [1];

% Beams
beams.nodesHead = [1];
beams.nodesEnd  = [2];
beams.sections  = [1];

% Loads — tip vertical force
loads.x.nodes  = [];  loads.x.value  = [];
loads.z.nodes  = [2]; loads.z.value  = [-10000];
loads.ry.nodes = [];  loads.ry.value = [];

% Solve
[displacements, endForces] = linearSolverFn(sections, nodes, 4, kinematic, beams, loads);

% Plot
plotFrameFn(nodes, beams, loads, kinematic, 'Labels', true);
```

## Hinge (kloub)

```matlab
beams.releases = false(nbeams, 2);
beams.releases(3, 1) = true;   % hinge at head of beam 3
beams.releases(2, 2) = true;   % hinge at end  of beam 2
```

- `releases(p, 1)` = true → moment release (ry) at **head node** of beam p
- `releases(p, 2)` = true → moment release (ry) at **end node** of beam p
- Only bending moment is released; axial and shear are preserved.

## Data structures

### `sections`
```matlab
sections.A   % (nsec×1) area [m²]
sections.Iz  % (nsec×1) 2nd moment of area [m⁴]
sections.E   % (nsec×1) Young's modulus [Pa]
```

### `nodes`
```matlab
nodes.x  % (nnodes×1) x-coordinates [m]
nodes.z  % (nnodes×1) z-coordinates [m]
```

### `kinematic`
```matlab
kinematic.x.nodes   % fixed ux
kinematic.z.nodes   % fixed uz
kinematic.ry.nodes  % fixed ry
```

### `loads`
```matlab
loads.x.nodes;  loads.x.value   % force in x [N]
loads.z.nodes;  loads.z.value   % force in z [N]
loads.ry.nodes; loads.ry.value  % moment [N·m]
```

### `endForces.local` — (6 × nelement)
```
row 1: N   at head [N]       (+ = tension)
row 2: Vz  at head [N]
row 3: My  at head [N·m]
row 4: N   at end  [N]
row 5: Vz  at end  [N]
row 6: My  at end  [N·m]
```

## Tests

```matlab
cd fem-2d-frame-matlab/tests
generate_references    % run once
run_all_tests          % run tests 1–3
```
