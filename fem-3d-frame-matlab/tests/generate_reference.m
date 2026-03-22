%% generate_reference.m
% ==========================================================================
%  Generate reference_eigenvalues.mat for one test using live OOFEM.
%
%  Run this script from the fem-stability-matlab/tests/ directory when
%  a new test is added or after changing the analysis code.
%
%  USAGE:
%    cd fem-stability-matlab/tests
%    testNum = 10;  % choose which test to (re-)generate
%    generate_reference
%
% ==========================================================================

if ~exist('testNum', 'var')
    error('Set testNum before running: testNum = 10; generate_reference');
end

scriptsDir = fileparts(mfilename('fullpath'));
srcDir     = fullfile(scriptsDir, '..', 'src');
addpath(srcDir);
addpath(scriptsDir);

testDir  = fullfile(scriptsDir, sprintf('Test %d', testNum));
oofemDir = fullfile(scriptsDir, 'oofem');

fprintf('Generating reference eigenvalues for Test %d ...\n', testNum);

%% Load test input
oldDir = cd(testDir);
run('test_input.m');  % sections, nodes, ndisc, kinematic, beams, loads
cd(oldDir);

%% Resolve cross-sections
if isfield(sections, 'A')
    % Direct properties — use as-is, fill defaults if missing
    resolvedSections = sections;
    if ~isfield(resolvedSections, 'E'), resolvedSections.E = 210e9; end
    if ~isfield(resolvedSections, 'v'), resolvedSections.v = 0.3;   end
else
    % Library lookup via sections.id
    sectionsFile = fullfile(scriptsDir, 'sectionsSet.mat');
    cs = importdata(sectionsFile);
    sections_full.A  = table2array(cs.L(:, 'A'));
    sections_full.Iz = table2array(cs.L(:, 'I_y'));
    sections_full.Iy = table2array(cs.L(:, 'I_z'));
    sections_full.Ix = table2array(cs.L(:, 'I_t'));

    nsec = size(sections.id, 1);
    resolvedSections.A  = zeros(nsec, 1);
    resolvedSections.Iy = zeros(nsec, 1);
    resolvedSections.Iz = zeros(nsec, 1);
    resolvedSections.Ix = zeros(nsec, 1);
    resolvedSections.E  = zeros(nsec, 1);
    resolvedSections.v  = zeros(nsec, 1);
    for i = 1:nsec
        id = sections.id(i);
        resolvedSections.A(i)  = sections_full.A(id);
        resolvedSections.Iy(i) = sections_full.Iy(id);
        resolvedSections.Iz(i) = sections_full.Iz(id);
        resolvedSections.Ix(i) = sections_full.Ix(id);
        resolvedSections.E(i)  = 210e9;
        resolvedSections.v(i)  = 0.3;
    end
end

%% Enrich beams struct for oofemInputFn
nodes.nnodes = numel(nodes.x);
nbeams_val   = numel(beams.nodesHead);
beams.nbeams = nbeams_val;
beams.disc   = ones(nbeams_val, 1) * ndisc;
beams.vertex = beamVertexFn(beams, nodes);
beams.XY     = XYtoRotBeamsFn(beams, beams.angles);

%% Write input.mat and run OOFEM
inputMat = fullfile(oofemDir, 'input.mat');
oofemInputFn(nodes, beams, loads, kinematic, resolvedSections, inputMat);

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

oofemPy = fullfile(oofemDir, 'oofem.py');
prevDir = cd(oofemDir);
cmd = sprintf('"%s" "%s"', pyPath, oofemPy);
[status, out] = system(cmd);
cd(prevDir);

if status ~= 0
    error('OOFEM runner failed (exit %d):\n%s', status, out);
end

%% Load and save reference eigenvalues
eigenMat = fullfile(oofemDir, 'eigen.mat');
ref = load(eigenMat, 'eigenvalues');
eigenvalues = ref.eigenvalues;

refFile = fullfile(testDir, 'reference_eigenvalues.mat');
save(refFile, 'eigenvalues');
fprintf('  Saved %d eigenvalues to:\n  %s\n', numel(eigenvalues), refFile);

posEig = sort(eigenvalues(eigenvalues > 0));
fprintf('  Positive eigenvalues: ');
fprintf('%.4f  ', posEig(1:min(10, end)));
fprintf('\n');
