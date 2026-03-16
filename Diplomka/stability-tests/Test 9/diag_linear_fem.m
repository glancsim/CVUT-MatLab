%% diag_linear_fem.m — Diagnostic for Test 9 linear FEM
% Runs Test 9 with ndisc=1 (single element per beam) and prints K + displacements
% to compare with OOFEM.

addpath(fullfile(fileparts(mfilename('fullpath')), '..', '..', 'Resources'));
test_input;  % Loads sections, nodes, ndisc, kinematic, beams, loads

% Override discretization: 1 element per beam
ndisc = 1;

%% Section properties
crossSectionsSet.import = importdata(fullfile(fileparts(mfilename('fullpath')), '..', 'sectionsSet.mat'));
crossSectionsSet.A  = table2array(crossSectionsSet.import.L(:,"A"));
crossSectionsSet.Iz = table2array(crossSectionsSet.import.L(:,"I_y"));  % swap
crossSectionsSet.Iy = table2array(crossSectionsSet.import.L(:,"I_z"));  % swap
crossSectionsSet.Ip = table2array(crossSectionsSet.import.L(:,"I_t"));

sections_out.id = sections.id;
for i = 1:size(sections_out.id, 1)
    sections_out.A(i,1)  = crossSectionsSet.A(sections_out.id(i));
    sections_out.Iy(i,1) = crossSectionsSet.Iy(sections_out.id(i));
    sections_out.Iz(i,1) = crossSectionsSet.Iz(sections_out.id(i));
    sections_out.Ix(i,1) = crossSectionsSet.Ip(sections_out.id(i));
    sections_out.E(i,1)  = 210e9;
    sections_out.v(i,1)  = 0.3;
end

fprintf('=== SECTION PROPERTIES ===\n');
fprintf('Section id  A         Iy         Iz         Ix\n');
for i = 1:length(sections_out.id)
    fprintf('  id=%2d     %.5e %.5e %.5e %.5e\n', ...
        sections_out.id(i), sections_out.A(i), sections_out.Iy(i), sections_out.Iz(i), sections_out.Ix(i));
end

%% FEM setup
nnodes = numel(nodes.x);
nodes.dofs = true(nnodes, 6);
nodes.dofs(kinematic.x.nodes, 1)  = false;
nodes.dofs(kinematic.y.nodes, 2)  = false;
nodes.dofs(kinematic.z.nodes, 3)  = false;
nodes.dofs(kinematic.rx.nodes, 4) = false;
nodes.dofs(kinematic.ry.nodes, 5) = false;
nodes.dofs(kinematic.rz.nodes, 6) = false;

nr = numel(beams.nodesHead);
beams.disc = ones(nr,1) * ndisc;
ng = max(max(beams.sections));

forceVector = sparse([loads.x.nodes*6-5; loads.y.nodes*6-4; loads.z.nodes*6-3; ...
                      loads.rx.nodes*6-2; loads.ry.nodes*6-1; loads.rz.nodes*6], ...
                     1, ...
                     [loads.x.value; loads.y.value; loads.z.value; ...
                      loads.rx.value; loads.ry.value; loads.rz.value], ...
                     nnodes*6, 1);
f = forceVector(reshape(reshape(nodes.dofs.', [], 1).', 1, [])');

nodes.ndofs  = sum(sum(nodes.dofs));
nodes.nnodes = nnodes;
beams.nbeams = nr;
beams.vertex = beamVertexFn(beams, nodes);
beams.codeNumbers = codeNumbersFn(beams, nodes);
beams.XY = XYtoRotBeamsFn(beams, beams.angles);

fprintf('\n=== XY VECTORS ===\n');
fprintf('Beam  XY(1)      XY(2)      XY(3)      |XY|\n');
for i = 1:nr
    fprintf('  %d  %8.5f  %8.5f  %8.5f  %8.5f\n', i, ...
        beams.XY(i,1), beams.XY(i,2), beams.XY(i,3), norm(beams.XY(i,:)));
end

elements = discretizationBeamsFn(beams, nodes);
elements.XY = XYtoElementFn(beams);
elements.sections = sectionToElementFn(sections_out, beams);
elements.ndofs = max(max(elements.codeNumbers));

endForces.global = sparse(elements.ndofs, 1);
endForces.global(1:max(max(beams.codeNumbers))) = f;

transformationMatrix = transformationMatrixFn(elements);

fprintf('\n=== TRANSFORMATION MATRICES (t = 3x3 rotation for each beam) ===\n');
for i = 1:nr
    T = transformationMatrix.matrices{i};
    t = T(1:3,1:3);
    fprintf('Beam %d (local x, y, z rows):\n', i);
    fprintf('  Cx = [%8.5f %8.5f %8.5f]  (beam axis)\n',    t(1,:));
    fprintf('  Cy = [%8.5f %8.5f %8.5f]  (local y)\n',       t(2,:));
    fprintf('  Cz = [%8.5f %8.5f %8.5f]  (local z)\n',       t(3,:));
    fprintf('  Length = %.5f\n', transformationMatrix.lengths(i));
end

stiffnesMatrix = stiffnessMatrixFn(elements, transformationMatrix);

fprintf('\n=== GLOBAL K (6x6, node 5 DOFs only) ===\n');
K6 = full(stiffnesMatrix.global(1:6, 1:6));
fprintf('DOF  Ux        Uy        Uz        Rx        Ry        Rz\n');
dofnames = {'Ux','Uy','Uz','Rx','Ry','Rz'};
for i = 1:6
    fprintf('%s  ', dofnames{i});
    for j = 1:6
        fprintf('%10.3e ', K6(i,j));
    end
    fprintf('\n');
end

[endForces.local, displ] = EndForcesFn(stiffnesMatrix, endForces, transformationMatrix, elements);

fprintf('\n=== NODE 5 DISPLACEMENTS (codes 1-6 = Ux,Uy,Uz,Rx,Ry,Rz) ===\n');
u = displ.global(1:6);
fprintf('  Ux = %12.6e\n', u(1));
fprintf('  Uy = %12.6e\n', u(2));
fprintf('  Uz = %12.6e\n', u(3));
fprintf('  Rx = %12.6e\n', u(4));
fprintf('  Ry = %12.6e\n', u(5));
fprintf('  Rz = %12.6e\n', u(6));

fprintf('\n=== OOFEM REFERENCE (from test.out) ===\n');
fprintf('  Ux = -1.382166e-07\n');
fprintf('  Uy = +4.050191e-07\n');
fprintf('  Uz = -4.891847e-07\n');
fprintf('  Rx = -1.211229e-07\n');
fprintf('  Ry = -5.385808e-08\n');
fprintf('  Rz = -5.938784e-08\n');

fprintf('\n=== LOCAL STIFFNESS K22 for each beam (6x6, tail DOFs) ===\n');
for i = 1:nr
    K_loc = stiffnesMatrix.local{i};
    K22 = K_loc(7:12, 7:12);
    fprintf('Beam %d K22_local:\n', i);
    for row = 1:6
        fprintf('  ');
        for col = 1:6
            fprintf('%10.3e ', K22(row,col));
        end
        fprintf('\n');
    end
end

fprintf('\nDiagnostic complete.\n');
