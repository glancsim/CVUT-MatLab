% diag_linear2.m – srovnání MATLAB vs OOFEM lineárních posunů, Test 9
% Spusť z adresáře stability-tests/Test 9/
BASEDIR = 'C:\GitHub\MatLab\.claude\worktrees\fervent-agnesi\Diplomka';
addpath(fullfile(BASEDIR,'Resources'));
addpath(fullfile(BASEDIR,'stability-tests'));

test_input;

css = importdata(fullfile(BASEDIR,'stability-tests','sectionsSet.mat'));
so.id = sections.id;
for i = 1:size(so.id,1)
    idx = find(css.L.id == so.id(i));
    so.A(i,1)  = table2array(css.L(idx,'A'));
    so.Iy(i,1) = table2array(css.L(idx,'I_z'));  % swap
    so.Iz(i,1) = table2array(css.L(idx,'I_y'));  % swap
    so.Ix(i,1) = table2array(css.L(idx,'I_t'));
    so.E(i,1)  = 210e9;
    so.v(i,1)  = 0.3;
end

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

fprintf('Beam vertices and XY:\n');
for b = 1:nr
    fprintf('  Beam %d: vertex=(%.4f,%.4f,%.4f)  XY=(%.4f,%.4f,%.4f)\n',...
        b, beams.vertex(b,:), beams.XY(b,:));
end

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
f = forceVector(reshape(reshape(nodes.dofs.', [], 1), 1, [])');
endForces.global = sparse(elements.ndofs, 1);
endForces.global(1:max(max(beams.codeNumbers))) = f;

T = transformationMatrixFn(elements);
K = stiffnessMatrixFn(elements, T);
[~, displ] = EndForcesFn(K, endForces, T, elements);
matlabAll = full(displ.global(1:nodes.ndofs));

oofemInputFn(nodes, beams, loads, kinematic, so, 'input.mat');
system('C:\Install\Python\python.exe C:\GitHub\python\oofemRunner\oofem.py');
d = dir('test.out*'); [~,nx] = max([d.datenum]);
od = parseOofemLinearFn(d(nx).name, nnodes);

dofNames = {'Ux','Uy','Uz','Rx','Ry','Rz'};
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

gmax = max(abs(oofemFree)) + 1e-30;
fprintf('\n--- MATLAB vs OOFEM (free DOFs) ---\n');
fprintf('%-6s %-10s %-14s %-14s %-10s\n','Code','Node/DOF','MATLAB','OOFEM','Err%');
idx = 0;
for n = 1:nnodes
    for dof = 1:6
        if nodes.dofs(n,dof)
            idx = idx+1;
            m = matlabAll(idx);  o = oofemFree(idx);
            err = abs(m-o)/gmax*100;
            fprintf('%-6d N%d/%-3s %14.6e %14.6e %10.4f%%\n',idx,n,dofNames{dof},m,o,err);
        end
    end
end
