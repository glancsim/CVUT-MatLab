# 3D Beam FEM — Linear & Stability Analysis

MATLAB implementation of a 3D Euler-Bernoulli beam finite element method for:

- **Linear static analysis** — displacements, reactions and internal forces
- **Linear buckling (stability) analysis** — critical load multipliers and mode shapes

No external software is required to run the solver or the validation tests.

---

## Repository structure

```
fem-stability-matlab/
├── src/                       ← Core FEM functions (add this folder to MATLAB path)
│   ├── linearSolverFn.m       ← Linear static analysis (main entry point)
│   ├── stabilitySolverFn.m    ← Linear buckling analysis (main entry point)
│   ├── stiffnessMatrixFn.m
│   ├── geometricMatrixFn.m
│   ├── transformationMatrixFn.m
│   ├── EndForcesFn.m
│   ├── criticalLoadFn.m
│   ├── sortValuesVectorFn.m
│   ├── discretizationBeamsFn.m
│   ├── beamVertexFn.m
│   ├── codeNumbersFn.m
│   ├── sectionToElementFn.m
│   ├── XYtoRotBeamsFn.m
│   ├── XYtoElementFn.m
│   └── XYtoBeamsFn.m
│
├── tests/                     ← Validation tests (9 spatial frame cases)
│   ├── run_all_tests.m        ← Run all 9 tests, generate report
│   ├── run_single_test.m      ← Helper called by run_all_tests
│   ├── sectionsSet.mat        ← Cross-section property library
│   ├── Test 1/
│   │   ├── test_input.m              ← Problem definition
│   │   └── reference_eigenvalues.mat ← Pre-computed OOFEM reference values
│   ├── Test 2/ … Test 9/     ← Same structure
│   └── results/               ← Auto-created when tests are run
│
└── examples/
    ├── example_linear_cantilever.m   ← 3D cantilever, tip load
    └── example_stability_column.m    ← Pinned-pinned column, Euler buckling
```

---

## Quick start

### 1. Add the source folder to the MATLAB path

```matlab
addpath('path/to/fem-stability-matlab/src')
```

Or run from the repository root:

```matlab
addpath(fullfile(pwd, 'src'))
```

### 2. Run an example

```matlab
cd examples
example_linear_cantilever      % linear analysis
example_stability_column       % buckling analysis
```

### 3. Run the validation tests

```matlab
cd tests
run_all_tests
```

Results are printed to the Command Window and saved to `tests/results/`.

---

## API reference

### `linearSolverFn` — Linear static analysis

```matlab
[displacements, endForces] = linearSolverFn(sections, nodes, ndisc, kinematic, beams, loads)
```

**Inputs** — all structs use column vectors, SI units throughout:

| Argument | Fields | Unit | Description |
|----------|--------|------|-------------|
| `sections` | `.A` | m² | Cross-sectional area `(nsec×1)` |
| | `.Iy` | m⁴ | 2nd moment of area about local y |
| | `.Iz` | m⁴ | 2nd moment of area about local z |
| | `.Ix` | m⁴ | Torsional (polar) moment of inertia |
| | `.E`  | Pa | Young's modulus |
| | `.v`  | — | Poisson's ratio |
| `nodes` | `.x .y .z` | m | Global Cartesian coordinates `(nnodes×1)` |
| `ndisc` | scalar | — | Number of finite elements per beam (≥ 1) |
| `kinematic` | `.x .y .z .rx .ry .rz .nodes` | — | Node indices with fixed DOFs |
| `beams` | `.nodesHead` | — | Start node index `(nbeams×1)` |
| | `.nodesEnd` | — | End node index |
| | `.sections` | — | Section index (1-based) |
| | `.angles` | deg | Cross-section rotation about beam axis |
| `loads` | `.x .y .z .rx .ry .rz .nodes` | — | Loaded node indices |
| | `.x .y .z .rx .ry .rz .value` | N / N·m | Load magnitudes |

**Outputs:**

| Variable | Field | Size | Description |
|----------|-------|------|-------------|
| `displacements` | `.global` | `ndofs×1` | Free-DOF displacements [m or rad] |
| | `.local` | `12×nelement` | Element displacements in local coords |
| `endForces` | `.local` | `12×nelement` | Internal forces/moments per element [N, N·m] |
| | `.global` | `ndofs×1` | Assembled RHS load vector |

Row index of `.local` (per element):
`1=N, 2=Vy, 3=Vz, 4=Mx, 5=My, 6=Mz` at start node; `7–12` at end node.

---

### `stabilitySolverFn` — Linear buckling analysis

```matlab
Results = stabilitySolverFn(sections, nodes, ndisc, kinematic, beams, loads)
```

Same inputs as `linearSolverFn`. The applied loads are treated as a **reference load pattern** — the solver finds the multiplier λ such that (λ × loads) causes buckling.

**Output:**

| Variable | Field | Size | Description |
|----------|-------|------|-------------|
| `Results` | `.values` | `10×1` | Critical load multipliers λᵢ, sorted ascending by \|λ\| |
| | `.vectors` | `ndofs×10` | Buckling mode shapes (unit-length eigenvectors) |

The first (smallest positive) critical load is:

```
F_critical = Results.values(1) × applied_reference_load
```

---

## Minimal usage example

```matlab
addpath('src')

%% Cross-section
sections.A  = 53.83e-4;   sections.Iy = 1943e-8;
sections.Iz = 388.6e-8;   sections.Ix = 20.98e-8;
sections.E  = 210e9;      sections.v  = 0.3;

%% Two-node beam along x-axis (L = 3 m)
nodes.x = [0; 3];  nodes.y = [0; 0];  nodes.z = [0; 0];

%% Boundary conditions — node 1 fully fixed
kinematic.x.nodes  = [1];  kinematic.y.nodes  = [1];  kinematic.z.nodes  = [1];
kinematic.rx.nodes = [1];  kinematic.ry.nodes = [1];  kinematic.rz.nodes = [1];

%% Beam topology
beams.nodesHead = [1];  beams.nodesEnd = [2];
beams.sections  = [1];  beams.angles   = [0];

%% Loads — 1 N axial compression at tip
loads.x.nodes = [2];  loads.x.value = [-1];
loads.y.nodes = [];   loads.y.value = [];
loads.z.nodes = [];   loads.z.value = [];
loads.rx.nodes = [];  loads.rx.value = [];
loads.ry.nodes = [];  loads.ry.value = [];
loads.rz.nodes = [];  loads.rz.value = [];

%% Run analyses
[displ, forces] = linearSolverFn(sections, nodes, 10, kinematic, beams, loads);
Results         = stabilitySolverFn(sections, nodes, 10, kinematic, beams, loads);

fprintf('Tip displacement (z): %.4e m\n', displ.global(end));
fprintf('Critical load multiplier 1: %.2f\n', Results.values(1));
```

---

## Validation tests

Nine spatial 3D frame problems are included. Each test:

1. Loads `test_input.m` — defines the structure and loading
2. Calls `stabilitySolverFn` to compute critical loads
3. Compares results against pre-computed reference eigenvalues (stored in `reference_eigenvalues.mat`, originally generated by [OOFEM](https://www.oofem.org))
4. Reports relative errors per buckling mode

Run all tests from the `tests/` directory:

```matlab
cd tests
run_all_tests
```

Typical results: errors below **0.1 %** for all 10 modes in all 9 tests (with `ndisc = 10`).

---

## Theory notes

### Element formulation
- 3D two-node Euler-Bernoulli beam element
- 6 DOFs per node: `ux uy uz rx ry rz`  →  12 DOFs per element
- Hermite (cubic) interpolation for bending; linear for axial and torsion
- Isoparametric coordinate transformation via 12×12 rotation matrices

### Linear analysis
Solves the system `K · u = f` where:
- `K` — global elastic stiffness matrix (assembled from element matrices)
- `f` — global nodal load vector
- `u` — free-DOF displacement vector

### Stability analysis
Solves the generalised eigenvalue problem `K · φ = λ · Kg · φ` where:
- `Kg` — geometric (initial stress) stiffness matrix, built from linear internal forces
- `λ` — critical load multiplier (eigenvalue)
- `φ` — buckling mode shape (eigenvector)

The 10 eigenvalues of smallest absolute value are returned by `criticalLoadFn` using MATLAB's `eigs`.

---

## Requirements

- MATLAB R2019b or later
- No additional toolboxes required (all solver and test scripts, including visualisation in `run_all_tests.m`, use base MATLAB functions)

---

## License

(c) S. Glanc, 2022–2025
