import scipy
import subprocess
import numpy as np
from scipy.io import savemat
import subprocess
import os

# Načti .mat soubor
data = scipy.io.loadmat('input.mat')

# Předpokládám, že struktura se jmenuje 'oofem'
oofem = data['oofem']

# Načtení dalších částí jako struktur
loads = oofem['loads'][0, 0]
loadsX = loads['X'][0, 0]
loadsY = loads['Y'][0, 0]
loadsZ = loads['Z'][0, 0]

kinematic = oofem['kinematic'][0, 0]
kinematicX = kinematic['x'][0, 0]['nodes'][0, 0]
kinematicY = kinematic['y'][0, 0]['nodes'][0, 0]
kinematicZ = kinematic['z'][0, 0]['nodes'][0, 0]
kinematicRx = kinematic['rx'][0, 0]['nodes'][0, 0]   
kinematicRy = kinematic['ry'][0, 0]['nodes'][0, 0] 
kinematicRz = kinematic['rz'][0, 0]['nodes'][0, 0]

sectionProp = oofem['sectionProp'][0, 0]
sectionPropA = sectionProp['A'][0, 0]
sectionPropIy = sectionProp['Iy'][0, 0]
sectionPropIz = sectionProp['Iz'][0, 0]
sectionPropIx = sectionProp['Ix'][0, 0]
sectionPropE = sectionProp['E'][0, 0]
sectionPropV = sectionProp['v'][0, 0]

sections = oofem['sections'][0, 0]
sectionId = sections['Id'][0, 0]
sectionRange = sections['range'][0, 0]


beams = oofem['beams'][0, 0]
nodes = oofem['nodes'][0, 0]

refNodes = oofem['refNode'][0, 0]

# Kloubová uvolnění (dofstocondense): matice (ndisc_total × 12), 1 = kondenzovat
releases = oofem['releases'][0, 0] if 'releases' in oofem.dtype.names else None

nnodes = nodes.shape[0] + refNodes.shape[0]

nbc = loadsX.shape[0] + loadsY.shape[0] + loadsZ.shape[0] + kinematicX.shape[0] + kinematicY.shape[0] + kinematicZ.shape[0] + kinematicRx.shape[0] + kinematicRy.shape[0] + kinematicRz.shape[0]
nmat = 1
ncrosssect = sectionPropA.shape[0]
nset = nbc + ncrosssect


# Otevření souboru pro zápis
with open('test.in', 'w', encoding='utf-8') as file:
    # For cyklus pro iteraci přes uzly
    file.write("test.out\n")
    file.write("Linear stability Test 1\n")  
    file.write("LinearStability nroot 10 rtolv 1.e-8 nmodules 1\n")  
    file.write("errorcheck\n")
    file.write("domain 3dShell\n")
    file.write("OutputManager tstep_all dofman_all element_all\n")
    file.write("ndofman " + str(nnodes) + " nelem " + str(beams.shape[0]) + " ncrosssect " + str(sectionPropA.shape[0]) + " nmat " + str(nmat) + " nbc " + str(nbc) + " nic 0 nltf 1 " + " nset " + str(nset) + "\n")

    file.write("#Nodes"'\n')

    for index, node in enumerate(nodes):
        # Formátování řetězce
        node_str = f"node {index+1} coords 3    {node[0]} {node[1]} {node[2]}"
        # Zápis textu do souboru
        file.write(node_str + '\n')  # Nodes

    file.write("#Reference nodes"'\n')

    for index, node in enumerate(refNodes):
        # Formátování řetězce
        refnode_str = f"node {nodes.shape[0] + index+1} coords 3    {node[0]} {node[1]} {node[2]}"
        # Zápis textu do souboru
        file.write(refnode_str + '\n')  # Nodes

    file.write("#Beams"'\n')

    for index, beam in enumerate(beams):
        dofs_to_condense = ""
        if releases is not None:
            rel = releases[index]
            cond_dofs = [i + 1 for i, v in enumerate(rel) if v != 0]
            if cond_dofs:
                dofs_to_condense = f"    dofstocondense {len(cond_dofs)} {' '.join(map(str, cond_dofs))}"
        beam_str = f"Beam3d {index+1}   nodes 2    {int(beam[0])} {int(beam[1])}    refnode {nodes.shape[0] + index+1}{dofs_to_condense}"
        file.write(beam_str + '\n')

    file.write("#Sections"'\n')

    for index, sectionArea in enumerate(sectionPropA):
        # Formátování řetězce
        section_str = f"SimpleCS {index+1}  area {sectionArea[0]}   Iy {sectionPropIy[index][0]}    Iz {sectionPropIz[index][0]}    Ik {sectionPropIx[index][0]}  beamShearCoeff 1.e30 material 1  set {index+1}"
        # Zápis textu do souboru
        file.write(section_str + '\n')  # Nodes

    file.write("#Materials"'\n')

    file.write("IsoLE 1 d 1.  E " + str(sectionPropE[0][0]) + " n " + str(sectionPropV[0][0]) + " tAlpha 1.2e-5" + '\n')

    file.write("#Boundary conditions"'\n')
    bcId = 0
    for index, loadX in enumerate(loadsX):
        bcId = bcId + 1
        # Formátování řetězce
        load_str = f"NodalLoad {bcId} loadTimeFunction 1 dofs 1 1 Components 1 {loadX[1]} set {ncrosssect+bcId}"
        # Zápis textu do souboru
        file.write(load_str + '\n')  # Nodes
    for index, loadY in enumerate(loadsY):
        bcId = bcId + 1
        # Formátování řetězce
        load_str = f"NodalLoad {bcId} loadTimeFunction 1 dofs 1 2 Components 1 {loadY[1]} set {ncrosssect+bcId}"
        # Zápis textu do souboru
        file.write(load_str + '\n')  # Nodes
    for index, loadZ in enumerate(loadsZ):
        bcId = bcId + 1
        # Formátování řetězce
        load_str = f"NodalLoad {bcId} loadTimeFunction 1 dofs 1 3 Components 1 {loadZ[1]} set {ncrosssect+bcId}"
        # Zápis textu do souboru
        file.write(load_str + '\n')
    for index, kinX in enumerate(kinematicX):
        bcId = bcId + 1
        # Formátování řetězce
        load_str = f"BoundaryCondition {bcId} loadTimeFunction 1 dofs 1 1 values 1 {0.0} set {ncrosssect+bcId}"
        # Zápis textu do souboru
        file.write(load_str + '\n')
    for index, kinY in enumerate(kinematicY):
        bcId = bcId + 1
        # Formátování řetězce
        load_str = f"BoundaryCondition {bcId} loadTimeFunction 1 dofs 1 2 values 1 {0.0} set {ncrosssect+bcId}"
        # Zápis textu do souboru
        file.write(load_str + '\n')
    for index, kinZ in enumerate(kinematicZ):
        bcId = bcId + 1
        # Formátování řetězce
        load_str = f"BoundaryCondition {bcId} loadTimeFunction 1 dofs 1 3 values 1 {0.0} set {ncrosssect+bcId}"
        # Zápis textu do souboru
        file.write(load_str + '\n')
    for index, kinRx in enumerate(kinematicRx):
        bcId = bcId + 1
        # Formátování řetězce
        load_str = f"BoundaryCondition {bcId} loadTimeFunction 1 dofs 1 4 values 1 {0.0} set {ncrosssect+bcId}"
        # Zápis textu do souboru
        file.write(load_str + '\n')
    for index, kinRy in enumerate(kinematicRy):
        bcId = bcId + 1
        # Formátování řetězce
        load_str = f"BoundaryCondition {bcId} loadTimeFunction 1 dofs 1 5 values 1 {0.0} set {ncrosssect+bcId}"
        # Zápis textu do souboru
        file.write(load_str + '\n')
    for index, kinRz in enumerate(kinematicRz):
        bcId = bcId + 1
        # Formátování řetězce
        load_str = f"BoundaryCondition {bcId} loadTimeFunction 1 dofs 1 6 values 1 {0.0} set {ncrosssect+bcId}"
        # Zápis textu do souboru
        file.write(load_str + '\n')
    file.write("ConstantFunction 1 f(t) 1." + '\n')
    file.write("#Sets"'\n')
    stId = 0
    for index, range in enumerate(sectionRange):
        # Formátování řetězce
        stId = stId + 1
        set_str = f'Set {stId} elementranges {{({int(range[0])} {int(range[1])})}}'
        # Zápis textu do souboru
        file.write(set_str + '\n')
    for index, loadX in enumerate(loadsX):
        stId = stId + 1
        # Formátování řetězce
        load_str = f'Set {stId} nodes 1 {int(loadX[0])}'
        # Zápis textu do souboru
        file.write(load_str + '\n')
    for index, loadY in enumerate(loadsY):
        stId = stId + 1
        # Formátování řetězce
        load_str = f'Set {stId} nodes 1 {int(loadY[0])}'
        # Zápis textu do souboru
        file.write(load_str + '\n')
    for index, loadZ in enumerate(loadsZ):
        stId = stId + 1
        # Formátování řetězce
        load_str = f'Set {stId} nodes 1 {int(loadZ[0])}'
        # Zápis textu do souboru
        file.write(load_str + '\n')
    for index, kinX in enumerate(kinematicX):
        stId = stId + 1
        # Formátování řetězce
        load_str = f'Set {stId} nodes 1 {int(kinX[0])}'
        # Zápis textu do souboru
        file.write(load_str + '\n')
    for index, kinY in enumerate(kinematicY):
        stId = stId + 1
        # Formátování řetězce
        load_str = f'Set {stId} nodes 1 {int(kinY[0])}'
        # Zápis textu do souboru
        file.write(load_str + '\n')
    for index, kinZ in enumerate(kinematicZ):
        stId = stId + 1
        # Formátování řetězce
        load_str = f'Set {stId} nodes 1 {int(kinZ[0])}'
        # Zápis textu do souboru
        file.write(load_str + '\n')
    for index, kinRx in enumerate(kinematicRx):
        stId = stId + 1
        # Formátování řetězce
        load_str = f'Set {stId} nodes 1 {int(kinRx[0])}'
        # Zápis textu do souboru
        file.write(load_str + '\n')
    for index, kinRy in enumerate(kinematicRy):
        stId = stId + 1
        # Formátování řetězce
        load_str = f'Set {stId} nodes 1 {int(kinRy[0])}'
        # Zápis textu do souboru
        file.write(load_str + '\n')
    for index, kinRz in enumerate(kinematicRz):
        stId = stId + 1
        # Formátování řetězce
        load_str = f'Set {stId} nodes 1 {int(kinRz[0])}'
        # Zápis textu do souboru
        file.write(load_str + '\n')



# Předpokládáme, že zde generuješ svůj vstupní soubor pro OOFEM
input_file = 'test.in'

# Příkaz pro spuštění OOFEM
oofem_command = f'wsl ./oofem -f {input_file}'

# Spusť OOFEM
try:
    result = subprocess.run(oofem_command, shell=True, check=True)
    print("OOFEM was successfully executed.")
except subprocess.CalledProcessError as e:
    print(f"An error occurred while running OOFEM: {e}")


# Cesta k souboru (relativní cesta, protože je ve stejném adresáři)
file_path = 'test.out'

# Otevření souboru a čtení obsahu
with open(file_path, 'r') as file:
    lines = file.readlines()

# Hledání sekce s vlastními čísly
eigenvalues_section = False
eigenvalues = []

for line in lines:
    # Zjistit, zda se nacházíme ve správné sekci
    if 'Eigen Values are:' in line:
        eigenvalues_section = True
        continue
    if eigenvalues_section:
        # Pokud narazíme na prázdný řádek, skončíme
        if line.strip() == '':
            break
        # Přidání hodnot do seznamu, ignorujeme nežádoucí řádky
        for ev in line.split():
            try:
                eigenvalues.append(float(ev))  # Převod na float
            except ValueError:
                continue  # Ignorujeme chyby při převodu

# Uložení vlastních čísel do souboru .mat
savemat('eigen.mat', {'eigenvalues': np.array(eigenvalues)})