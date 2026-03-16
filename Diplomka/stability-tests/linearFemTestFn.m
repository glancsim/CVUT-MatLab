function [errors, matlabDispl, oofemDispl, forceErrors] = linearFemTestFn(sections, nodes, ndisc, kinematic, beams, loads)
% linearFemTestFn - Compare MATLAB linear FEM displacements vs OOFEM reference
%
% Runs MATLAB linear static FEM, re-uses OOFEM (via stability run) to get
% reference displacements from test.out, and returns per-DOF relative errors
% for all free DOFs of the original (non-discretized) nodes.
%
% Inputs:
%   sections   - sections.id
%   nodes      - nodes.x, nodes.y, nodes.z
%   ndisc      - beam discretization count
%   kinematic  - kinematic.x/y/z/rx/ry/rz.nodes
%   beams      - beams.nodesHead, nodesEnd, sections, angles
%   loads      - loads.x/y/z/rx/ry/rz.nodes/value
%
% Outputs:
%   errors      - Relative errors per free DOF [%] (absolute for near-zero ref)
%   matlabDispl - MATLAB free-DOF displacements of original nodes (column vector)
%   oofemDispl  - OOFEM free-DOF displacements of original nodes (column vector)
%   forceErrors - Relative errors of local end forces (12 x nelement) [%]
%
% Note: Call from within the test directory (cd to testDir first).

%% SECTION SETUP
crossSectionsSet.import = importdata('../sectionsSet.mat');
crossSectionsSet.A  = table2array(crossSectionsSet.import.L(:, 'A'));
crossSectionsSet.Iz = table2array(crossSectionsSet.import.L(:, 'I_y'));  % intentional swap
crossSectionsSet.Iy = table2array(crossSectionsSet.import.L(:, 'I_z'));  % intentional swap
crossSectionsSet.Ip = table2array(crossSectionsSet.import.L(:, 'I_t'));

sections_out.id = sections.id;
for i = 1:size(sections_out.id, 1)
    sections_out.A(i,1)  = crossSectionsSet.A(sections_out.id(i));
    sections_out.Iy(i,1) = crossSectionsSet.Iy(sections_out.id(i));
    sections_out.Iz(i,1) = crossSectionsSet.Iz(sections_out.id(i));
    sections_out.Ix(i,1) = crossSectionsSet.Ip(sections_out.id(i));
    sections_out.E(i,1)  = 210e9;
    sections_out.v(i,1)  = 0.3;
end

%% NODE & SUPPORT SETUP
nnodes = numel(nodes.x);
nodes.dofs = true(nnodes, 6);
nodes.dofs(kinematic.x.nodes,  1) = false;
nodes.dofs(kinematic.y.nodes,  2) = false;
nodes.dofs(kinematic.z.nodes,  3) = false;
nodes.dofs(kinematic.rx.nodes, 4) = false;
nodes.dofs(kinematic.ry.nodes, 5) = false;
nodes.dofs(kinematic.rz.nodes, 6) = false;

nodes.ndofs  = sum(sum(nodes.dofs));
nodes.nnodes = nnodes;

%% BEAM & ELEMENT SETUP
nr = numel(beams.nodesHead);
beams.disc    = ones(nr, 1) * ndisc;
beams.nbeams  = nr;
beams.vertex  = beamVertexFn(beams, nodes);
beams.codeNumbers = codeNumbersFn(beams, nodes);
beams.XY      = XYtoRotBeamsFn(beams, beams.angles);

elements = discretizationBeamsFn(beams, nodes);
elements.XY       = XYtoElementFn(beams);
elements.sections = sectionToElementFn(sections_out, beams);
elements.ndofs    = max(max(elements.codeNumbers));

%% FORCE VECTOR
forceVector = sparse([loads.x.nodes*6-5; loads.y.nodes*6-4; loads.z.nodes*6-3; ...
                      loads.rx.nodes*6-2; loads.ry.nodes*6-1; loads.rz.nodes*6], ...
                     1, ...
                     [loads.x.value; loads.y.value; loads.z.value; ...
                      loads.rx.value; loads.ry.value; loads.rz.value], ...
                     nnodes*6, 1);
f = forceVector(reshape(reshape(nodes.dofs.', [], 1).', 1, [])');

endForces.global = sparse(elements.ndofs, 1);
endForces.global(1:max(max(beams.codeNumbers))) = f;

%% MATLAB LINEAR SOLVE
transformationMatrix = transformationMatrixFn(elements);
stiffnesMatrix       = stiffnessMatrixFn(elements, transformationMatrix);
[localEndForces, displ] = EndForcesFn(stiffnesMatrix, endForces, transformationMatrix, elements);

% Extract free-DOF displacements of original nodes only
% Code numbers 1..nodes.ndofs belong to original nodes (listed first)
matlabAll = full(displ.global(1:nodes.ndofs));

%% RUN OOFEM AND PARSE LINEAR DISPLACEMENTS + INTERNAL FORCES
oofemInputFn(nodes, beams, loads, kinematic, sections_out, 'input.mat');
system('C:\Install\Python\python.exe C:\GitHub\python\oofemRunner\oofem.py');

% On Windows+WSL the file may have a hidden trailing byte; use dir() to get actual name
d = dir('test.out*');
if isempty(d)
    error('OOFEM output file test.out not found in %s', pwd);
end
[~, newest] = max([d.datenum]);
testOutFile = d(newest).name;

oofemDisplAll = parseOofemLinearFn(testOutFile, nnodes);           % (nnodes x 6)
oofemForces   = parseOofemInternalForcesFn(testOutFile, elements.nelement); % (12 x nelement)

%% BUILD MATCHED FREE-DOF VECTORS (same ordering as MATLAB codes)
% MATLAB code numbers: iterate node 1..nnodes, DOF 1..6, assign codes to free DOFs
matlabDispl = zeros(nodes.ndofs, 1);
oofemDisplFree = zeros(nodes.ndofs, 1);
idx = 0;
for n = 1:nnodes
    for d = 1:6
        if nodes.dofs(n, d)
            idx = idx + 1;
            matlabDispl(idx)    = matlabAll(idx);
            oofemDisplFree(idx) = oofemDisplAll(n, d);
        end
    end
end

%% COMPUTE ERRORS (normalise by global max displacement to avoid near-zero blow-up)
globalMaxDispl = max(abs(oofemDisplFree)) + 1e-30;
errors = abs(matlabDispl - oofemDisplFree) / globalMaxDispl * 100;

oofemDispl = oofemDisplFree;

%% COMPUTE FORCE ERRORS (normalise by element's max |force| to avoid near-zero blow-up)
forceErrors = zeros(12, elements.nelement);
globalMaxForce = max(abs(oofemForces(:))) + 1e-30;
for e = 1:elements.nelement
    elemRef = max(abs(oofemForces(:, e)));
    if elemRef < 1e-6 * globalMaxForce
        elemRef = globalMaxForce;  % fall back to global scale for near-zero elements
    end
    for d = 1:12
        forceErrors(d, e) = abs(localEndForces(d, e) - oofemForces(d, e)) / elemRef * 100;
    end
end
end
