"""
oofem.py  —  2D frame linear-static OOFEM runner

Reads input.mat (written by MATLAB oofemInputFn.m), generates test.in for
OOFEM LinearStatic analysis with Beam2d elements (domain 2dBeam), runs
OOFEM via WSL, parses nodal displacements from test.out, and saves the
result to displacements.mat.

Coordinate mapping:
    Our XZ plane  →  OOFEM XZ plane (2dBeam domain lies in XZ)
    Our x         →  OOFEM x  (axial)
    Our z         →  OOFEM z  (transverse/vertical)
    Our ry        →  OOFEM R_v  (DOF 5, rotation about y)

OOFEM DOF codes for 2dBeam (XZ plane convention):
    1 = D_u  (x-displacement, axial)
    3 = D_w  (z-displacement, transverse)
    5 = R_v  (rotation about y-axis, bending)

Local element DOF numbering for Beam2d (used in dofstocondense):
    1 = D_u at head    4 = D_u at end
    2 = D_w at head    5 = D_w at end
    3 = R_v at head    6 = R_v at end

(c) S. Glanc, 2026
"""

import re
import subprocess
import numpy as np
import scipy.io
from scipy.io import savemat, loadmat

# ---------------------------------------------------------------------------
# Load input
# (CWD is set to this script's directory by oofemTestFn.m before invocation)
# ---------------------------------------------------------------------------
data  = loadmat('input.mat')
oofem = data['oofem']

nodes_mat    = oofem['nodes'][0, 0]          # (nnodes × 2)  [x, z]
beams_mat    = oofem['beams'][0, 0]          # (nbeams × 2)  [head, end]
releases_mat = oofem['releases'][0, 0]       # (nbeams × 2)
sectProp     = oofem['sectionProp'][0, 0]
loads        = oofem['loads'][0, 0]
kinematic    = oofem['kinematic'][0, 0]

nnodes = nodes_mat.shape[0]
nbeams = beams_mat.shape[0]

A_arr  = sectProp['A'][0, 0]    # (nbeams × 1)
Iz_arr = sectProp['Iz'][0, 0]
E_arr  = sectProp['E'][0, 0]

loadsX  = loads['X'][0, 0]      # (n × 2) [node, value] or (0 × 2)
loadsZ  = loads['Z'][0, 0]
loadsRY = loads['RY'][0, 0]

kinX  = kinematic['x'][0, 0]['nodes'][0, 0]
kinZ  = kinematic['z'][0, 0]['nodes'][0, 0]
kinRY = kinematic['ry'][0, 0]['nodes'][0, 0]

# ---------------------------------------------------------------------------
# Counts
# ---------------------------------------------------------------------------
ncrosssect = nbeams
nmat       = 1
nbc        = (loadsX.shape[0] + loadsZ.shape[0] + loadsRY.shape[0]
              + kinX.shape[0] + kinZ.shape[0] + kinRY.shape[0])
nset       = ncrosssect + nbc

# ---------------------------------------------------------------------------
# Write test.in
# ---------------------------------------------------------------------------
with open('test.in', 'w', encoding='utf-8') as f:
    f.write("test.out\n")
    f.write("2D Frame linear static analysis\n")
    f.write("LinearStatic nsteps 1 nmodules 1\n")
    f.write("errorcheck\n")
    f.write("domain 2dBeam\n")
    f.write("OutputManager tstep_all dofman_all element_all\n")
    f.write(f"ndofman {nnodes} nelem {nbeams} ncrosssect {ncrosssect} "
            f"nmat {nmat} nbc {nbc} nic 0 nltf 1 nset {nset}\n")

    # --- nodes (coords 3: x 0 z — 2dBeam domain lies in XZ plane) ---
    f.write("#Nodes\n")
    for i, nd in enumerate(nodes_mat):
        f.write(f"node {i+1} coords 3  {nd[0]}  0.0  {nd[1]}\n")

    # --- Beam2d elements ---
    f.write("#Beams\n")
    for i, bm in enumerate(beams_mat):
        rel = releases_mat[i]
        cond = []
        if rel[0] != 0: cond.append(3)   # hinge at head → condense R_z (local DOF 3)
        if rel[1] != 0: cond.append(6)   # hinge at end  → condense R_z (local DOF 6)
        cond_str = ""
        if cond:
            cond_str = f"    dofstocondense {len(cond)} {' '.join(map(str, cond))}"
        f.write(f"Beam2d {i+1}   nodes 2    {int(bm[0])} {int(bm[1])}{cond_str}\n")

    # --- cross-sections (one per beam) ---
    f.write("#Sections\n")
    for i in range(nbeams):
        f.write(f"SimpleCS {i+1}  area {A_arr[i][0]}   Iz {Iz_arr[i][0]}   "
                f"beamShearCoeff 1.e30  material 1  set {i+1}\n")

    # --- material (single IsoLE, E from section 0) ---
    f.write("#Material\n")
    f.write(f"IsoLE 1 d 1.  E {E_arr[0][0]}  n 0.3  tAlpha 1.2e-5\n")

    # --- boundary conditions ---
    f.write("#Boundary conditions\n")
    bcId = 0
    for row in loadsX:
        bcId += 1
        f.write(f"NodalLoad {bcId} loadTimeFunction 1 dofs 1 1 "
                f"Components 1 {row[1]} set {ncrosssect+bcId}\n")
    for row in loadsZ:
        bcId += 1
        f.write(f"NodalLoad {bcId} loadTimeFunction 1 dofs 1 3 "
                f"Components 1 {row[1]} set {ncrosssect+bcId}\n")
    for row in loadsRY:
        bcId += 1
        f.write(f"NodalLoad {bcId} loadTimeFunction 1 dofs 1 5 "
                f"Components 1 {row[1]} set {ncrosssect+bcId}\n")
    for row in kinX:
        bcId += 1
        f.write(f"BoundaryCondition {bcId} loadTimeFunction 1 dofs 1 1 "
                f"values 1 0. set {ncrosssect+bcId}\n")
    for row in kinZ:
        bcId += 1
        f.write(f"BoundaryCondition {bcId} loadTimeFunction 1 dofs 1 3 "
                f"values 1 0. set {ncrosssect+bcId}\n")
    for row in kinRY:
        bcId += 1
        f.write(f"BoundaryCondition {bcId} loadTimeFunction 1 dofs 1 5 "
                f"values 1 0. set {ncrosssect+bcId}\n")
    f.write("ConstantFunction 1 f(t) 1.\n")

    # --- sets ---
    f.write("#Sets\n")
    for i in range(nbeams):
        f.write(f"Set {i+1} elementranges {{({i+1} {i+1})}}\n")
    stId = nbeams
    for row in loadsX:
        stId += 1
        f.write(f"Set {stId} nodes 1 {int(row[0])}\n")
    for row in loadsZ:
        stId += 1
        f.write(f"Set {stId} nodes 1 {int(row[0])}\n")
    for row in loadsRY:
        stId += 1
        f.write(f"Set {stId} nodes 1 {int(row[0])}\n")
    for row in kinX:
        stId += 1
        f.write(f"Set {stId} nodes 1 {int(row[0])}\n")
    for row in kinZ:
        stId += 1
        f.write(f"Set {stId} nodes 1 {int(row[0])}\n")
    for row in kinRY:
        stId += 1
        f.write(f"Set {stId} nodes 1 {int(row[0])}\n")

# ---------------------------------------------------------------------------
# Run OOFEM via WSL — WSL inherits the Windows CWD (set by MATLAB cd)
# so test.out is written to the same directory Python reads from.
# ---------------------------------------------------------------------------
try:
    result = subprocess.run('wsl ./oofem -f test.in', shell=True, check=True)
    print("OOFEM executed successfully.")
except subprocess.CalledProcessError as e:
    print(f"OOFEM error: {e}")

# ---------------------------------------------------------------------------
# Parse nodal displacements from test.out
#
# OOFEM LinearStatic output (DofManager output section) typically contains:
#
#   DofManager N [node] output:
#      dof  1  (D_u)  a 1    :     0.000000e+00
#      dof  2  (D_v)  a 1    :    -5.208929e-02
#      dof  6  (R_z)  a 1    :    -1.953348e-02
#
# We collect dof 1 → ux, dof 2 → uz (our z), dof 6 → ry (our rotation).
# ---------------------------------------------------------------------------
with open('test.out', 'r') as f:
    lines = f.readlines()

disp_data   = {}   # node_id (int) → {dof_code: value}
current_node = None

for line in lines:
    # Detect new DofManager block
    m_node = re.search(r'DofManager\s+(\d+)', line)
    if m_node:
        current_node = int(m_node.group(1))
        if current_node not in disp_data:
            disp_data[current_node] = {}
        continue

    if current_node is not None:
        # Match "dof N ... : value"  (scientific or fixed notation)
        m_dof = re.search(
            r'dof\s+(\d+).*?:\s*([-+]?[0-9]*\.?[0-9]+(?:[eE][+-]?[0-9]+)?)',
            line)
        if m_dof:
            dof_id = int(m_dof.group(1))
            value  = float(m_dof.group(2))
            disp_data[current_node][dof_id] = value

# Build (nnodes × 3) matrix: columns = [ux, uz, ry]
displacements = np.zeros((nnodes, 3))
for i in range(1, nnodes + 1):
    if i in disp_data:
        displacements[i-1, 0] = disp_data[i].get(1, 0.0)   # D_u  → ux
        displacements[i-1, 1] = disp_data[i].get(3, 0.0)   # D_w  → uz
        displacements[i-1, 2] = disp_data[i].get(5, 0.0)   # R_v  → ry

savemat('displacements.mat', {'displacements': displacements})
print(f"Displacements saved to displacements.mat  ({nnodes} nodes)")
