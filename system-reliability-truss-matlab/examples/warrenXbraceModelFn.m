function model = warrenXbraceModelFn(opts)
% warrenXbraceModelFn  Shared model setup for the Warren X-brace demo truss.
%
% Builds the geometry, topology, boundary conditions, random-variable spec
% and FSD-sized sections of the single-span, simply-supported Warren truss
% with FULL X-bracing used by example_warren_xbrace.m (interactive demo),
% example_warren_xbrace_paper.m (paper numbers) and make_paper_figures.m
% (paper figures) -- factored out so the geometry/RV block lives in exactly
% one place. See example_warren_xbrace.m's header for the modelling
% rationale (why 3 panels, why 4 resistance groups, why f_y*A_FSD).
%
% DETERMINISM: everything this function does is deterministic (linear FEM +
% the FSD stress-ratio iteration). It draws no random numbers, so it may be
% called before or after rng() without affecting downstream results.
%
% INPUT:
%   opts - (struct, optional)
%       .verbose - logical, echo FSD progress and a geometry summary
%                  (default false)
%
% OUTPUT: model - (struct)
%   .nodes, .members, .kinematic - fem-2d-truss-matlab convention
%   .sections    - FSD-converged .A [m^2] and .E [Pa] per section group
%   .rvSpec      - .resGroup/.resMean/.resStd/.loadCases/.loadMean/.loadStd
%   .meanLoads   - mean combined load case (used for FSD and for plotting)
%   .role        - (nmembers x 1) section/resistance group of each member
%   .roleNames   - (1 x 4) cell, human-readable group names
%   .gH          - degree of static indeterminacy
%   .cutSets     - minimal cut-sets (Phase A only, cheap)
%   .fsdHistory  - iteration history from fullyStressedDesignFn
%   .sigmaAllow, .f_y - the two stress levels used for sizing [Pa]
%   .nPanels, .Lpanel, .H - geometry parameters [-, m, m]
%   .topLoadNodes - loaded top-chord node indices
%
% See also: example_warren_xbrace, example_warren_xbrace_paper,
%           make_paper_figures, fullyStressedDesignFn
%
% (c) S. Glanc, 2026

if nargin < 1, opts = struct(); end
if ~isfield(opts, 'verbose'), opts.verbose = false; end

%% Geometry
nPanels = 3;
Lpanel  = 4;    % m
H       = 2;    % m

nBot = nPanels + 1;                    % 4 bottom nodes
xBot = (0:nPanels)' * Lpanel;
zBot = zeros(nBot, 1);
xTop = xBot;
zTop = H * ones(nBot, 1);

nodes.x = [xBot; xTop];
nodes.z = [zBot; zTop];

nBotNodes = 1:nBot;
nTopNodes = (nBot+1):(2*nBot);

bc_head = nBotNodes(1:end-1)'; bc_end = nBotNodes(2:end)';       % bottom chord
tc_head = nTopNodes(1:end-1)'; tc_end = nTopNodes(2:end)';       % top chord
vert_head = nBotNodes';        vert_end = nTopNodes';            % verticals
diag1_head = nBotNodes(1:end-1)'; diag1_end = nTopNodes(2:end)';     % ascending diagonal
diag2_head = nBotNodes(2:end)';   diag2_end = nTopNodes(1:end-1)';   % descending diagonal (X-brace)

members.nodesHead = [bc_head; tc_head; vert_head; diag1_head; diag2_head];
members.nodesEnd  = [bc_end; tc_end; vert_end; diag1_end; diag2_end];
members.nmembers  = numel(members.nodesHead);
nm = members.nmembers;

% Section/resistance role: 1=bottom chord, 2=top chord, 3=vertical, 4=diagonal (both directions)
role = zeros(nm, 1);
idx = 1;
nBC = numel(bc_head);    role(idx:idx+nBC-1) = 1; idx = idx + nBC;
nTC = numel(tc_head);    role(idx:idx+nTC-1) = 2; idx = idx + nTC;
nV  = numel(vert_head);  role(idx:idx+nV-1)  = 3; idx = idx + nV;
nD1 = numel(diag1_head); role(idx:idx+nD1-1) = 4; idx = idx + nD1;
nD2 = numel(diag2_head); role(idx:idx+nD2-1) = 4; idx = idx + nD2;
members.sections = role;

sections.A = [4e-4; 4e-4; 4e-4; 6e-4];   % m^2: [bottom, top, vertical, diagonal] -- INITIAL GUESS, overwritten by FSD below
sections.E = 210e9 * ones(4, 1);           % Pa, steel

% Boundary conditions: pin (node 1) + roller (node nBot=4)
kinematic.x.nodes = [1];
kinematic.z.nodes = [1; nBot];

if opts.verbose
    fprintf('=== Warren X-brace truss demo (simply-supported, %d panels) ===\n', nPanels);
    fprintf('nmembers = %d, nnodes = %d\n', nm, numel(nodes.x));
end

%% Confirm indeterminacy
A_eq = equilibriumMatrixFn(nodes, members, kinematic);
[cutSets, gH, ~] = nullSpaceCutSetsFn(A_eq);
if opts.verbose
    fprintf('gH = %d, minimal cut-sets = %d\n', gH, numel(cutSets));
end

%% Random variable spec (loads first -- resistances depend on FSD sizing below)
rvSpec.resGroup = role;

topLoadNodes = nTopNodes(2:end-1)';    % interior top-chord nodes (6, 7)
loads_p6.x.nodes = []; loads_p6.x.value = [];
loads_p6.z.nodes = topLoadNodes(1); loads_p6.z.value = -1;
loads_p7.x.nodes = []; loads_p7.x.value = [];
loads_p7.z.nodes = topLoadNodes(2); loads_p7.z.value = -1;

% Load level: a first trial at 50 kN gave beta_sys = 5.26 (Pf ~ 7e-8, an
% uninformatively safe structure); 95 kN gave beta_sys = 0.53 (absurdly
% unsafe, useful only to prove the MC path works). 75 kN lands in a
% realistic "somewhat under-designed but not absurd" range and is what the
% paper reports.
%
% MONTE CARLO NOTE (corrects an earlier comment here): 75 kN does NOT give
% "~1-2 % MC failures". The actual system failure probability at this load
% is Pf_sys ~ 1.1e-04, i.e. 0.011 % -- roughly a hundred times smaller. A
% 2e4-sample progressiveCollapseMCFn run therefore expects ~2 failures and
% says essentially nothing; a meaningful MC cross-check of beta_sys needs
% on the order of 1e7 samples (which is why it is a separate job, see
% tests/mc_neptun/).
rvSpec.loadCases = {loads_p6, loads_p7};
rvSpec.loadMean  = [75; 75] * 1e3;      % N, mean 75 kN each
rvSpec.loadStd   = rvSpec.loadMean * 0.15;

% Mean combined load case -- used both for FSD sizing (deterministic) and
% for the geometry plot.
meanLoads.x.nodes = []; meanLoads.x.value = [];
meanLoads.z.nodes = topLoadNodes;
meanLoads.z.value = -rvSpec.loadMean;      % N, mean downward point loads at nodes 6,7

%% Fully-stressed design: size each section GROUP to sigmaAllow under mean load
sigmaAllow = 210e6;    % Pa, allowable (working) stress -- FSD sizing target
f_y        = 355e6;    % Pa, S355 nominal yield -- drives rvSpec.resMean below

if opts.verbose
    fprintf('\n=== fullyStressedDesignFn (sigmaAllow = %.0f MPa) ===\n', sigmaAllow/1e6);
end
fsdOpts.verbose = opts.verbose;
[sections, fsdHistory] = fullyStressedDesignFn(nodes, members, kinematic, sections, meanLoads, sigmaAllow, fsdOpts);
if opts.verbose
    fprintf('converged areas [cm^2]: %s\n', mat2str(sections.A' * 1e4, 4));
end

rvSpec.resMean = f_y * sections.A;      % N: f_y/sigmaAllow ~= 1.69 acts as an implicit ASD safety factor
rvSpec.resStd  = rvSpec.resMean * 0.08; % COV(R) = 0.08

%% Pack
model.nodes        = nodes;
model.members      = members;
model.kinematic    = kinematic;
model.sections     = sections;
model.rvSpec       = rvSpec;
model.meanLoads    = meanLoads;
model.role         = role;
model.roleNames    = {'bottom chord', 'top chord', 'vertical', 'diagonal'};
model.gH           = gH;
model.cutSets      = cutSets;
model.fsdHistory   = fsdHistory;
model.sigmaAllow   = sigmaAllow;
model.f_y          = f_y;
model.nPanels      = nPanels;
model.Lpanel       = Lpanel;
model.H            = H;
model.topLoadNodes = topLoadNodes;

end
