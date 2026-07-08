% example_3story_truss.m
%
% 3-story planar truss -- PRIMARY end-to-end regression test for Phase C
% (Cornell index + PNET system reliability), Wei & Deng (2022), Structural
% Safety 95:102175, section 6.2, Fig. 4 / Table 2-4. Geometry rendered
% directly from the source PDF by the coordinator (not reconstructed from
% text alone).
%
% GEOMETRY (exact):
%   1: (0,0)       2: (1.219,0)
%   3: (0,0.9144)  4: (1.219,0.9144)
%   5: (0,1.8288)  6: (1.219,1.8288)
%   7: (0,2.7432)  8: (1.219,2.7432)
%   Supports: nodes 1,2 both pinned (x AND z) -> 12 free DOF.
%
% MEMBERS (16, fully X-braced in all 3 panels -- unlike the 15-bar truss
% which only X-braced its end panels):
%   1:1-2 2:3-4 3:5-6 4:7-8 (chords)
%   5:1-3 6:2-4 7:3-5 8:4-6 9:5-7 10:6-8 (verticals)
%   11:1-4 12:2-3 13:3-6 14:4-5 15:5-8 16:6-7 (diagonals, both per panel)
%
% LOADS: 3 independent horizontal point loads at nodes 3,5,7 (mean 44.45
% kN, COV 0.1, independent, Gaussian).
%
% SECTIONS/RESISTANCE (Table 2, 8 types, COV(R)=0.05 for all, Gaussian,
% fully correlated WITHIN a type, independent ACROSS types):
%   Type 1: {4,15}      A=0.94 cm^2   meanR=25.944 kN
%   Type 2: {2}         A=1.30 cm^2   meanR=35.880 kN
%   Type 3: {3,9,10}    A=1.38 cm^2   meanR=38.088 kN
%   Type 4: {8}         A=3.00 cm^2   meanR=82.800 kN
%   Type 5: {1}         A=3.71 cm^2   meanR=102.396 kN
%   Type 6: {7,13,14}   A=3.89 cm^2   meanR=107.364 kN
%   Type 7: {11,12,16}  A=4.72 cm^2   meanR=130.272 kN
%   Type 8: {5,6}       A=8.69 cm^2   meanR=239.844 kN
%
% E = 206e9 Pa for all members. eta=0 (brittle -- matches the paper, which
% does NOT use ductile residual-force redistribution for this example).
%
% TARGET: beta_sys ~ 3.00 (paper's own method: 3.001162; independent MCS
% 1e7: 3.013374). Anything in ~2.9-3.1 is a successful reproduction (exact
% match not expected -- our cut-set search is more complete than the
% paper's, see metodika.md sec. 2.1).
%
% (c) S. Glanc, 2026

clear; close all;
srcDir = fullfile(fileparts(mfilename('fullpath')), '..', 'src');
femDir = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'fem-2d-truss-matlab', 'src');
addpath(srcDir); addpath(femDir);

%% Geometry
nodes.x = [0; 1.219; 0; 1.219; 0; 1.219; 0; 1.219];
nodes.z = [0; 0; 0.9144; 0.9144; 1.8288; 1.8288; 2.7432; 2.7432];

kinematic.x.nodes = [1; 2];
kinematic.z.nodes = [1; 2];

members.nodesHead = [1;3;5;7;  1;2;3;4;5;6;  1;2;3;4;5;6];
members.nodesEnd  = [2;4;6;8;  3;4;5;6;7;8;  4;3;6;5;8;7];
members.nmembers  = 16;

% Section/type assignment per member (Table 2)
typeOfMember = zeros(16, 1);
typeOfMember([4,15])    = 1;
typeOfMember([2])       = 2;
typeOfMember([3,9,10])  = 3;
typeOfMember([8])       = 4;
typeOfMember([1])       = 5;
typeOfMember([7,13,14]) = 6;
typeOfMember([11,12,16])= 7;
typeOfMember([5,6])     = 8;
members.sections = typeOfMember;

A_cm2  = [0.94, 1.30, 1.38, 3.00, 3.71, 3.89, 4.72, 8.69];   % cm^2
meanR_kN = [25.944, 35.880, 38.088, 82.800, 102.396, 107.364, 130.272, 239.844];

sections.A = A_cm2' * 1e-4;     % cm^2 -> m^2
sections.E = 206e9 * ones(8, 1);

fprintf('=== 3-story truss (Wei & Deng 2022, sec. 6.2) ===\n');
fprintf('nmembers = %d\n', members.nmembers);

%% Confirm gH via Phase A
A_eq = equilibriumMatrixFn(nodes, members, kinematic);
[cutSetsCheck, gH, ~] = nullSpaceCutSetsFn(A_eq);
fprintf('gH (computed) = %d   (expected 4 = 16 - 12)\n', gH);
fprintf('cut-sets found = %d   (paper: 78, expected >= 78 per metodika.md sec. 2.1)\n', numel(cutSetsCheck));
sizesFound = cellfun(@numel, cutSetsCheck);
fprintf('  size distribution: %s\n', mat2str(histcounts(sizesFound, 0.5:1:(gH+1.5))));

%% Random variable spec
rvSpec.resGroup = typeOfMember;
rvSpec.resMean  = (meanR_kN * 1e3)';          % kN -> N
rvSpec.resStd   = rvSpec.resMean * 0.05;      % COV(R) = 0.05

loads_p3.x.nodes = 3; loads_p3.x.value = 1; loads_p3.z.nodes = []; loads_p3.z.value = [];
loads_p5.x.nodes = 5; loads_p5.x.value = 1; loads_p5.z.nodes = []; loads_p5.z.value = [];
loads_p7.x.nodes = 7; loads_p7.x.value = 1; loads_p7.z.nodes = []; loads_p7.z.value = [];

rvSpec.loadCases = {loads_p3, loads_p5, loads_p7};
rvSpec.loadMean  = [44.45; 44.45; 44.45] * 1e3;    % kN -> N
rvSpec.loadStd   = rvSpec.loadMean * 0.1;          % COV = 0.1

%% System reliability
opts.eta     = 0;      % brittle -- matches the paper's own worked example
opts.rho0    = 0.7;
opts.verbose = true;

results = systemReliabilityFn(nodes, members, kinematic, sections, rvSpec, opts);

fprintf('\n=== RESULT ===\n');
fprintf('beta_sys (computed) = %.4f\n', results.beta_sys);
fprintf('Paper (Wei & Deng own method)  = 3.001162\n');
fprintf('Paper (MCS, 1e7 samples)       = 3.013374\n');
if results.beta_sys >= 2.9 && results.beta_sys <= 3.1
    fprintf('STATUS: within [2.9, 3.1] -- reproduction considered SUCCESSFUL\n');
else
    fprintf('STATUS: OUTSIDE [2.9, 3.1] -- investigate\n');
end
