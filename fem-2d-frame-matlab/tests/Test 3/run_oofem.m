% run_oofem.m  — OOFEM verification for Test 3 (portal frame with hinge)
%
% Compares MATLAB 2D frame FEM solution against OOFEM LinearStatic
% analysis using Beam2d elements (domain 2dBeam).
%
% REQUIREMENTS:
%   - OOFEM binary at tests/oofem/oofem  (Linux ELF, run via WSL)
%   - Python 3 with scipy, numpy
%
% (c) S. Glanc, 2026

testDir = fileparts(mfilename('fullpath'));
srcDir  = fullfile(testDir, '..', '..', 'src');
addpath(srcDir);

run(fullfile(testDir, 'test_input.m'));

fprintf('=== OOFEM Test 3: portal frame with hinge ===\n');
[errors, d_matlab, d_oofem] = oofemTestFn(nodes, beams, loads, kinematic, sections);

% Detailed node comparison
fprintf('\nNode displacements comparison:\n');
fprintf('  %-6s  %-14s  %-14s  %-14s  %-14s  %-14s  %-14s\n', ...
    'Node', 'ux_MATLAB', 'ux_OOFEM', 'uz_MATLAB', 'uz_OOFEM', 'ry_MATLAB', 'ry_OOFEM');
for i = 1:size(d_matlab, 1)
    fprintf('  %-6d  %+.6e  %+.6e  %+.6e  %+.6e  %+.6e  %+.6e\n', ...
        i, d_matlab(i,1), d_oofem(i,1), ...
           d_matlab(i,2), d_oofem(i,2), ...
           d_matlab(i,3), d_oofem(i,3));
end

maxErr = max([errors.ux; errors.uz; errors.ry]);
fprintf('\nMax error: %.4g %%\n', maxErr);
if maxErr < 0.01
    fprintf('PASSED  (< 0.01 %%)\n');
else
    fprintf('FAILED  (> 0.01 %%)\n');
end
