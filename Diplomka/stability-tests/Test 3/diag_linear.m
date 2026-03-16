% diag_linear.m – diagnostika lineárního FEM vs OOFEM pro Test 3
% Spusť z adresáře stability-tests/Test 3/

BASEDIR = 'C:\GitHub\MatLab\.claude\worktrees\fervent-agnesi\Diplomka';
addpath(fullfile(BASEDIR, 'Resources'));
addpath(fullfile(BASEDIR, 'stability-tests'));

test_input;

%% Sekce (stejná logika jako linearFemTestFn)
css = importdata(fullfile(BASEDIR, 'stability-tests', 'sectionsSet.mat'));
css_A  = table2array(css.L(:,'A'));
css_Iz = table2array(css.L(:,'I_y'));  % swap
css_Iy = table2array(css.L(:,'I_z'));  % swap
css_Ip = table2array(css.L(:,'I_t'));

so.id = sections.id;
for i = 1:size(so.id,1)
    so.A(i,1)  = css_A(so.id(i));
    so.Iy(i,1) = css_Iy(so.id(i));
    so.Iz(i,1) = css_Iz(so.id(i));
    so.Ix(i,1) = css_Ip(so.id(i));
    so.E(i,1)  = 210e9;
    so.v(i,1)  = 0.3;
end

fprintf('sections: E=%.3e A=%.4e Iy=%.4e Iz=%.4e\n', so.E(1), so.A(1), so.Iy(1), so.Iz(1));

%% Nastavení uzlů / podpor / prvků
nnodes = numel(nodes.x);
nodes.dofs = true(nnodes, 6);
nodes.dofs(kinematic.x.nodes,  1) = false;
nodes.dofs(kinematic.y.nodes,  2) = false;
nodes.dofs(kinematic.z.nodes,  3) = false;
nodes.dofs(kinematic.rx.nodes, 4) = false;
nodes.dofs(kinematic.ry.nodes, 5) = false;
nodes.dofs(kinematic.rz.nodes, 6) = false;
nodes.ndofs  = sum(nodes.dofs(:));
nodes.nnodes = nnodes;

nr = numel(beams.nodesHead);
beams.disc    = ones(nr,1) * ndisc;
beams.nbeams  = nr;
beams.vertex  = beamVertexFn(beams, nodes);
beams.codeNumbers = codeNumbersFn(beams, nodes);
beams.XY      = XYtoRotBeamsFn(beams, beams.angles);

fprintf('XY beam1: %.6f %.6f %.6f\n', beams.XY(1,:));
fprintf('XY beam2: %.6f %.6f %.6f\n', beams.XY(2,:));

elements = discretizationBeamsFn(beams, nodes);
elements.XY       = XYtoElementFn(beams);
elements.sections = sectionToElementFn(so, beams);
elements.ndofs    = max(max(elements.codeNumbers));

forceVector = sparse([loads.x.nodes*6-5; loads.y.nodes*6-4; loads.z.nodes*6-3; ...
                      loads.rx.nodes*6-2; loads.ry.nodes*6-1; loads.rz.nodes*6], ...
                     1, ...
                     [loads.x.value; loads.y.value; loads.z.value; ...
                      loads.rx.value; loads.ry.value; loads.rz.value], ...
                     nnodes*6, 1);
f = forceVector(reshape(reshape(nodes.dofs.', [], 1).', 1, [])');

endForces.global = sparse(elements.ndofs, 1);
endForces.global(1:max(max(beams.codeNumbers))) = f;

%% MATLAB solve
transformationMatrix = transformationMatrixFn(elements);
stiffnesMatrix       = stiffnessMatrixFn(elements, transformationMatrix);
[~, displ] = EndForcesFn(stiffnesMatrix, endForces, transformationMatrix, elements);

matlabAll = full(displ.global(1:nodes.ndofs));
fprintf('\nMATLAB free DOFs:');
fprintf(' %.4e', matlabAll);
fprintf('\n');

%% OOFEM
oofemInputFn(nodes, beams, loads, kinematic, so, 'input.mat');
system('C:\Install\Python\python.exe C:\GitHub\python\oofemRunner\oofem.py');
d = dir('test.out*'); [~,nx] = max([d.datenum]);
od = parseOofemLinearFn(d(nx).name, nnodes);

fprintf('\nOOFEM displacements (all nodes, all DOFs):\n');
dofNames = {'Ux','Uy','Uz','Rx','Ry','Rz'};
for n = 1:nnodes
    for dof = 1:6
        fprintf('  Node %d %s: %.6e\n', n, dofNames{dof}, od(n,dof));
    end
end

% Build OOFEM free-DOF vector same order as MATLAB
oofemFree = zeros(nodes.ndofs,1);
idx = 0;
for n = 1:nnodes
    for dof = 1:6
        if nodes.dofs(n,dof)
            idx = idx+1;
            oofemFree(idx) = od(n,dof);
        end
    end
end

fprintf('\n--- Comparison (free DOFs) ---\n');
fprintf('%-6s %-10s %-12s %-12s %-10s\n','Code','Node/DOF','MATLAB','OOFEM','Err%');
idx = 0;
for n = 1:nnodes
    for dof = 1:6
        if nodes.dofs(n,dof)
            idx = idx+1;
            m = matlabAll(idx);  o = oofemFree(idx);
            ref = max(abs(o), 1e-15);
            err = abs(m-o)/ref*100;
            fprintf('%-6d N%d/%-3s  %12.4e %12.4e %10.4f%%\n', idx, n, dofNames{dof}, m, o, err);
        end
    end
end
