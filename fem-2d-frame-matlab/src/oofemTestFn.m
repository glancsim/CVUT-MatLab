function [errors, d_matlab, d_oofem] = oofemTestFn(nodes, beams, loads, kinematic, sections)
% oofemTestFn  Run OOFEM 2D linear-static analysis and compare with MATLAB.
%
% Generates OOFEM input from the given 2D frame model, runs OOFEM via the
% Python runner in tests/oofem/, and compares nodal displacements with the
% MATLAB FEM solution (ndisc = 1).
%
% INPUTS:
%   nodes, beams, loads, kinematic, sections  — standard 2D frame structs
%
% OUTPUTS:
%   errors   - struct with fields .ux, .uz, .ry:
%              (nnodes × 1) relative errors [%] per original node
%   d_matlab - (nnodes × 3) MATLAB displacements [ux, uz, ry] per node
%   d_oofem  - (nnodes × 3) OOFEM  displacements [ux, uz, ry] per node
%
% REQUIREMENTS:
%   tests/oofem/oofem.py  — Python 2D OOFEM runner
%   tests/oofem/oofem     — OOFEM Linux binary (run via WSL)
%   Python 3 with scipy and numpy
%
% (c) S. Glanc, 2026

%--------------------------------------------------------------------------
% Locate tests/oofem/ relative to src/
%--------------------------------------------------------------------------
srcDir   = fileparts(mfilename('fullpath'));
oofemDir = fullfile(srcDir, '..', 'tests', 'oofem');

oofemPy = fullfile(oofemDir, 'oofem.py');
if ~exist(oofemPy, 'file')
    error('oofemTestFn: oofem.py not found at:\n  %s', oofemPy);
end

%--------------------------------------------------------------------------
% Write input.mat
%--------------------------------------------------------------------------
inputMat = fullfile(oofemDir, 'input.mat');
oofemInputFn(nodes, beams, loads, kinematic, sections, inputMat);

%--------------------------------------------------------------------------
% Locate Python executable
%--------------------------------------------------------------------------
[~, pyRaw] = system('where python 2>nul');
pyRaw = strtrim(pyRaw);
if isempty(pyRaw)
    [~, pyRaw] = system('where python3 2>nul');
    pyRaw = strtrim(pyRaw);
end
if ~isempty(pyRaw)
    lines  = strsplit(pyRaw, newline);
    pyPath = strtrim(lines{1});
else
    pyPath = 'C:\Install\Python\python.exe';
end
if ~exist(pyPath, 'file')
    error('oofemTestFn: Python not found (%s).', pyPath);
end

%--------------------------------------------------------------------------
% Run OOFEM via Python runner
%--------------------------------------------------------------------------
prevDir    = cd(oofemDir);
cleanupObj = onCleanup(@() cd(prevDir));   %#ok<NASGU>

cmd = sprintf('"%s" "%s"', pyPath, oofemPy);
[status, out] = system(cmd);
if status ~= 0
    error('oofemTestFn: OOFEM runner returned error %d.\n%s', status, out);
end

%--------------------------------------------------------------------------
% Load OOFEM displacements (nnodes × 3): [ux, uz, ry]
%--------------------------------------------------------------------------
dispMat = fullfile(oofemDir, 'displacements.mat');
ref     = load(dispMat, 'displacements');
d_oofem = ref.displacements;    % (nnodes × 3)

%--------------------------------------------------------------------------
% MATLAB linear analysis with ndisc = 1 (matches OOFEM 1-element-per-beam)
%--------------------------------------------------------------------------
[displacements, ~] = linearSolverFn(sections, nodes, 1, kinematic, beams, loads);

% Rebuild DOF-to-node mapping for original nodes
nnodes     = numel(nodes.x);
nodes_dofs = true(nnodes, 3);
nodes_dofs(kinematic.x.nodes,  1) = false;
nodes_dofs(kinematic.z.nodes,  2) = false;
nodes_dofs(kinematic.ry.nodes, 3) = false;

dofNums = zeros(nnodes, 3);
m = 0;
for g = 1:nnodes
    for j = 1:3
        if nodes_dofs(g, j)
            m = m + 1;
            dofNums(g, j) = m;
        end
    end
end

d_full    = full(displacements.global);
d_matlab  = zeros(nnodes, 3);
for g = 1:nnodes
    for j = 1:3
        c = dofNums(g, j);
        if c > 0 && c <= numel(d_full)
            d_matlab(g, j) = d_full(c);
        end
    end
end

%--------------------------------------------------------------------------
% Compute errors — normalise by max displacement range (avoid div/0)
%--------------------------------------------------------------------------
denom_ux = max(max(abs(d_oofem(:,1))), 1e-12);
denom_uz = max(max(abs(d_oofem(:,2))), 1e-12);
denom_ry = max(max(abs(d_oofem(:,3))), 1e-12);

errors.ux = abs(d_matlab(:,1) - d_oofem(:,1)) / denom_ux * 100;
errors.uz = abs(d_matlab(:,2) - d_oofem(:,2)) / denom_uz * 100;
errors.ry = abs(d_matlab(:,3) - d_oofem(:,3)) / denom_ry * 100;

maxErr = max([errors.ux; errors.uz; errors.ry]);
fprintf('  OOFEM: max displacement error = %.4g %%\n', maxErr);

%--------------------------------------------------------------------------
% Plot comparison
%--------------------------------------------------------------------------
figure;
nodeIdx = 1:nnodes;
subplot(3,1,1); bar(nodeIdx, [d_matlab(:,1), d_oofem(:,1)]);
legend('MATLAB','OOFEM'); ylabel('u_x [m]'); title('Nodal displacements — MATLAB vs OOFEM');
subplot(3,1,2); bar(nodeIdx, [d_matlab(:,2), d_oofem(:,2)]);
legend('MATLAB','OOFEM'); ylabel('u_z [m]');
subplot(3,1,3); bar(nodeIdx, [d_matlab(:,3), d_oofem(:,3)]);
legend('MATLAB','OOFEM'); ylabel('\phi_y [rad]'); xlabel('Node #');
end
