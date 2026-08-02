function [nodes, members, kinematic, sections, rvSpec] = mcNeptunSetup(root)
% mcNeptunSetup  Verbatim setup from MC_NEPTUN_BRIEF.md section 5 --
% geometry, loads, FSD sizing and random variables for the Warren X-brace
% truss, identical to the analytical run in example_warren_xbrace.m.
%
% Adds the three required source directories to the MATLAB path and ASSERTS
% the two deterministic checks from the brief (FSD areas, beta_min). If
% either fails the setup does not match the analytical run and the function
% errors out rather than letting a 1e8-sample job burn on a wrong model.
%
%   root - (optional) directory CONTAINING both repos, i.e. the parent of
%          system-reliability-truss-matlab/ and fem-2d-truss-matlab/.
%          Defaults to three levels above this file, which resolves
%          correctly whenever the repo layout is preserved.
%
% Verified on this setup (MATLAB R2026a):
%   areas [cm^2] = [7.79481 6.49091 1.48074 4.67493]
%   beta_min     = 3.909383 (member 11)  ->  Pf_min = 4.62660874e-05
%
% (c) S. Glanc, 2026

if nargin < 1 || isempty(root)
    root = fullfile(fileparts(mfilename('fullpath')), '..', '..', '..');
end

addpath(fullfile(root, 'system-reliability-truss-matlab', 'src'));
addpath(fullfile(root, 'system-reliability-truss-matlab', 'tests'));
addpath(fullfile(root, 'fem-2d-truss-matlab', 'src'));

%% geometry: 3 panels x 4 m, 2 m high, full X-bracing, 16 members
nPanels = 3; Lpanel = 4; H = 2;
nBot = nPanels + 1;
xBot = (0:nPanels)' * Lpanel;
nodes.x = [xBot; xBot];
nodes.z = [zeros(nBot,1); H * ones(nBot,1)];

nBotNodes = 1:nBot;  nTopNodes = (nBot+1):(2*nBot);
members.nodesHead = [nBotNodes(1:end-1)'; nTopNodes(1:end-1)'; nBotNodes'; ...
                     nBotNodes(1:end-1)'; nBotNodes(2:end)'];
members.nodesEnd  = [nBotNodes(2:end)';   nTopNodes(2:end)';   nTopNodes'; ...
                     nTopNodes(2:end)';   nTopNodes(1:end-1)'];
members.nmembers  = numel(members.nodesHead);          % 16

% section groups: 1 bottom chord, 2 top chord, 3 vertical, 4 diagonal
role = [1;1;1; 2;2;2; 3;3;3;3; 4;4;4; 4;4;4];
members.sections = role;

% supports: pin at node 1, roller at node 4
kinematic.x.nodes = 1;
kinematic.z.nodes = [1; nBot];

%% loads: two independent Gaussian point loads, mean 75 kN, COV 0.15
topLoadNodes = nTopNodes(2:end-1)';                     % nodes 6 and 7
l6.x.nodes = []; l6.x.value = []; l6.z.nodes = topLoadNodes(1); l6.z.value = -1;
l7.x.nodes = []; l7.x.value = []; l7.z.nodes = topLoadNodes(2); l7.z.value = -1;
rvSpec.resGroup  = role;
rvSpec.loadCases = {l6, l7};
rvSpec.loadMean  = [75; 75] * 1e3;
rvSpec.loadStd   = rvSpec.loadMean * 0.15;

meanLoads.x.nodes = []; meanLoads.x.value = [];
meanLoads.z.nodes = topLoadNodes;
meanLoads.z.value = -rvSpec.loadMean;

%% FSD sizing
sec0.A = [4e-4; 4e-4; 4e-4; 6e-4]; sec0.E = 210e9 * ones(4,1);
fsdOpts.verbose = false;
sections = fullyStressedDesignFn(nodes, members, kinematic, sec0, ...
                                 meanLoads, 210e6, fsdOpts);

%% resistances: R = f_y * A per GROUP, COV 0.08
rvSpec.resMean = 355e6 * sections.A;
rvSpec.resStd  = rvSpec.resMean * 0.08;

%% ---- deterministic checks (brief section 5) -- abort on mismatch --------
areasExp = [7.79481; 6.49091; 1.48074; 4.67493];        % cm^2
areasGot = sections.A(:) * 1e4;
fprintf('areas [cm^2] = %s\n', mat2str(areasGot', 6));
if max(abs(areasGot - areasExp) ./ areasExp) > 1e-5
    error('mcNeptunSetup:areaMismatch', ...
        ['FSD areas do not match the analytical run.\n' ...
         '  got    %s\n  expect %s\nSetup is wrong -- do not run the MC.'], ...
        mat2str(areasGot', 6), mat2str(areasExp', 6));
end

comp  = componentReliabilityFn(nodes, members, kinematic, sections, rvSpec);
[bmin, imin] = min(comp.beta);
fprintf('beta_min = %.6f (expect 3.909383), member %d\n', bmin, imin);
fprintf('Pf_min   = %.8e (expect 4.62660874e-05)\n', normcdf(-bmin));
if abs(bmin - 3.909383) > 1e-5
    error('mcNeptunSetup:betaMismatch', ...
        'beta_min = %.6f, expected 3.909383. Setup is wrong -- do not run the MC.', bmin);
end

fprintf('setup checks PASSED\n');
end
